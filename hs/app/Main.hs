{-# HLINT ignore "Use bimap" #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# HLINT ignore "Use lambda-case" #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}

module Main (main) where

import Colog (LoggerT, logMsg, logTextStdout, usingLoggerT)
import Colog.Concurrent (defCapacity, withBackgroundLogger)
import Control.Concurrent.Async (concurrently_)
import Control.Concurrent.Async.Pool (mapConcurrently, withTaskGroup)
import Control.Concurrent.STM (STM, atomically)
import Control.Concurrent.STM.TBMQueue (TBMQueue, closeTBMQueue, newTBMQueueIO, tryReadTBMQueue, writeTBMQueue)
import Control.Lens ((^?))
import Control.Monad (replicateM_, unless, void, when)
import Control.Monad.IO.Class (MonadIO (..))
import Data.Aeson (FromJSON, ToJSON, Value (..))
import Data.Aeson.Lens (key, nth, _String)
import Data.ByteString (ByteString)
import Data.ByteString qualified as S8
import Data.Either (fromRight, isLeft)
import Data.Foldable (traverse_)
import Data.Function (fix, (&))
import Data.HashMap.Strict qualified as Map
import Data.HashSet qualified as Set
import Data.Hashable (Hashable)
import Data.List (partition)
import Data.List qualified as DL
import Data.Maybe (fromJust, isJust, isNothing)
import Data.String (IsString (fromString))
import Data.String.Interpolate (i)
import Data.Text (Text, intercalate, strip)
import Data.Text qualified as Text
import Data.Text.IO qualified as T
import Data.Text.IO qualified as Text
import Data.Time (UTCTime)
import Data.Yaml (decodeEither', decodeFileEither)
import Data.Yaml qualified as Yaml
import GHC.Generics (Generic)
import GHC.IO.Handle (BufferMode (NoBuffering), hSetBuffering)
import GHC.IO.Handle.FD (withFile)
import GHC.IO.IOMode (IOMode (AppendMode))
import Network.HTTP.Client (Response (..))
import Network.HTTP.Client.Conduit (Request (method))
import Network.HTTP.Simple (httpJSONEither, setRequestBodyJSON, setRequestHeader)
import Network.HTTP.Types (status200)
import System.IO (stdout)
import Text.Pretty.Simple (CheckColorTty (CheckColorTty), OutputOptions (outputOptionsCompact), defaultOutputOptionsDarkBg, pPrintOpt)
import Turtle (Alternative (empty), mktree, rm, rmtree, shellStrictWithErr, testfile)

-- VS Code Marketplace request
data Criterion = Criterion
  { filterType :: Int
  , value :: Text
  }
  deriving (Generic, ToJSON)

data Filter = Filter
  { criteria :: [Criterion]
  , pageNumber :: Int
  , pageSize :: Int
  , sortBy :: Int
  , sortOrder :: Int
  }
  deriving (Generic, ToJSON)

data Req = Req
  { filters :: [Filter]
  , assetTypes :: [String]
  , flags :: Int
  }
  deriving (Generic, ToJSON)

requestExtension :: Text -> Req
requestExtension name =
  Req
    { filters =
        [ Filter
            { criteria =
                [ Criterion
                    { filterType = 8
                    , value = "Microsoft.VisualStudio.Code"
                    }
                , Criterion
                    { filterType = 7
                    , value = name
                    }
                , Criterion
                    { filterType = 12
                    , value = "4096"
                    }
                ]
            , pageNumber = 1
            , pageSize = 2
            , sortBy = 0
            , sortOrder = 0
            }
        ]
    , assetTypes = []
    , flags = 946
    }

_PAGE_COUNT :: Int
_PAGE_COUNT = 54

data Target = VSCodeMarketplace | OpenVSX

data ExtensionConfig = ExtensionConfig
  { name :: Text
  , publisher :: Text
  , lastUpdated :: UTCTime
  }
  deriving (Generic, FromJSON, ToJSON, Show, Eq, Hashable)

data ExtensionData = ExtensionData
  { name :: Text
  , version :: Text
  , publisher :: Text
  , url :: Text
  , sha256 :: Text
  , lastUpdated :: UTCTime
  }
  deriving (Generic, FromJSON, ToJSON, Show)

fixName :: Text -> Text
fixName name
  | Text.take 1 name == "_" = Text.drop 1 name
  | otherwise = name

apiUrl :: Target -> String
apiUrl target =
  targetSelect
    target
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    "https://open-vsx.org/api"

getExtension :: Target -> TBMQueue ExtensionData -> TBMQueue ExtensionConfig -> ExtensionConfig -> LoggerT Text IO ()
getExtension target extDataQueue extFailedConfigQueue c@ExtensionConfig{..} = do
  let
    select = targetSelect target
    -- when serialized, names starting with a digit like '^\d' become like '_\d.*'
    -- we'll internally use them in this '_0' form
    -- in nix expressions, we should write them in their correct form
    fixedName = fixName name
    fixedPublisher = fixName publisher
    fixedExtName :: Text = [i|#{fixedPublisher}.#{fixedName}|]
    request =
      select
        ( setRequestBodyJSON (requestExtension fixedExtName) $
            setRequestHeader "Accept" ["application/json;api-version=6.1-preview.1"] $
              setRequestHeader "Content-Type" ["application/json"] $
                (fromString "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"){method = "POST"}
        )
        ( setRequestHeader "Accept" ["application/json"] $
            setRequestHeader "Content-Type" ["application/json"] $
              (fromString [i|https://open-vsx.org/api/#{fixedPublisher}/#{fixedName}|]){method = "GET"}
        )
  response <- httpJSONEither request
  isFailed <-
    if responseStatus response /= status200 || isLeft (responseBody response)
      then do
        logMsg @Text [i|[Fail] Requesting the server. Response status: #{responseStatus response}. Server response: #{responseBody response}|]
        pPrintOpt CheckColorTty defaultOutputOptionsDarkBg{outputOptionsCompact = True} response
        pure True
      else do
        let body :: Value = fromRight undefined (responseBody response)
        let extVersion =
              select
                (body ^? key "results" . nth 0 . key "extensions" . nth 0 . key "versions" . nth 0 . key "version" . _String)
                (body ^? key "version" . _String)
        if isNothing extVersion
          then do
            logMsg @Text [i|[Fail] Getting info about #{fixedExtName}|]
            pure True
          else do
            let version = fromJust extVersion
                url =
                  select
                    [i|https://#{fixedPublisher}.gallery.vsassets.io/_apis/public/gallery/publisher/#{fixedPublisher}/extension/#{fixedName}/#{version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage|]
                    [i|https://open-vsx.org/api/#{fixedPublisher}/#{fixedName}/#{version}/file/#{fixedExtName}-#{version}.vsix|]
            logMsg @Text [i|[Start] Fetching #{fixedExtName} from #{url}|]
            (_, strip -> sha256, errText) <- shellStrictWithErr [i|nix store prefetch-file --json #{url} | jq -r .hash|] empty
            if not (Text.null errText)
              then do
                logMsg @Text [i|[Fail] Fetching #{fixedExtName} to nix store from #{url}|]
                pure True
              else do
                logMsg @Text [i|[Succes] Fetched #{fixedExtName} from #{url}|]
                liftIO $ atomically $ writeTBMQueue extDataQueue $ ExtensionData{..}
                pure False
  when isFailed $ liftIO $ atomically $ writeTBMQueue extFailedConfigQueue c

mkNixExtensions :: [ExtensionData] -> Text
mkNixExtensions es =
  [i|
{ fetchgit, fetchurl, fetchFromGitHub }:
{
#{intercalate "" (mkNixExtension <$> es)}
}
|]

mkNixExtension :: ExtensionData -> Text
mkNixExtension ExtensionData{..} =
  [i|
  "#{fixName publisher}-#{fixName name}" = {
    name = "#{fixName name}";
    publisher = "#{fixName publisher}";
    version = "#{version}";
    src = fetchurl {
      url = "#{url}";
      name = "#{fixName name}-#{version}.zip";
      sha256 = "#{sha256}";
    };
  };
|]

targetSelect :: Target -> p -> p -> p
targetSelect target f g =
  case target of
    VSCodeMarketplace -> f
    OpenVSX -> g

showTarget :: Target -> String
showTarget target = targetSelect target "vscode-marketplace" "open-vsx"

flushTBMQueue :: TBMQueue a -> STM (Maybe [a])
flushTBMQueue q = flip fix [] $ \ret contents -> do
  s <- tryReadTBMQueue q
  case s of
    Just (Just a) -> ret (a : contents)
    Nothing -> pure Nothing
    _ -> pure $ pure contents

extLogger :: FilePath -> FilePath -> TBMQueue ExtensionData -> TBMQueue ExtensionConfig -> IO ()
extLogger extDataFile extConfigFile extDataQ extConfigQ = do
  withFile extDataFile AppendMode $ \extDataH ->
    withFile extConfigFile AppendMode $ \extConfigH -> do
      hSetBuffering extDataH NoBuffering
      hSetBuffering extConfigH NoBuffering
      fix $ \ret -> do
        extData <- atomically $ flushTBMQueue extDataQ
        extConfig <- atomically $ flushTBMQueue extConfigQ
        maybe (pure ()) (\case [] -> pure (); x_ -> S8.hPutStr extDataH $ Yaml.encode x_) extData
        maybe (pure ()) (\case [] -> pure (); x_ -> S8.hPutStr extConfigH $ Yaml.encode x_) extConfig
        unless (isNothing extData && isNothing extConfig) ret

main' :: FilePath -> Int -> Int -> Target -> IO ()
main' dataDir nThreads queueCapacity target = do
  let targetYaml :: FilePath = [i|#{showTarget target}.yaml|]
      targetNix :: FilePath = [i|#{showTarget target}.nix|]

      rootTmpDir :: FilePath = "tmp"
      fetchedTmpDir :: FilePath = [i|#{rootTmpDir}/fetched|]
      failedTmpDir :: FilePath = [i|#{rootTmpDir}/failed|]

      newDir :: FilePath = [i|#{dataDir}/new|]
      newConfigPath = [i|#{newDir}/#{targetYaml}|]
      oldDir :: FilePath = [i|#{dataDir}/old|]
      generatedDir :: FilePath = [i|#{dataDir}/generated|]

      mkTarget :: FilePath -> FilePath
      mkTarget x = [i|#{x}/#{targetYaml}|]

  traverse_ (\x -> mktree [i|#{x}|]) [fetchedTmpDir, failedTmpDir, generatedDir]
  traverse_ (\x -> let f = [i|#{mkTarget x}|] in testfile f >>= (`when` rm f)) [fetchedTmpDir, failedTmpDir]
  let f = [i|#{generatedDir}/#{targetNix}|]
   in testfile f >>= (`when` rm f)

  withBackgroundLogger defCapacity logTextStdout (pure ()) $ \stdoutLog -> do
    hSetBuffering stdout NoBuffering
    configsOld <- fromRight [] <$> decodeFileEither (mkTarget oldDir)
    let mkKey :: Text -> Text -> UTCTime -> Text
        mkKey publisher name lastUpdated = [i|#{publisher}-#{name}-#{lastUpdated}|]
        configsOldMap :: Map.HashMap Text ExtensionData
        configsOldMap =
          Map.fromList
            ((\d@ExtensionData{..} -> (mkKey publisher name lastUpdated, d)) <$> configsOld)
    configsNew <- Set.toList . Set.fromList . fromRight [] <$> decodeFileEither newConfigPath
    let (present, missing) =
          partition
            (isJust . fst)
            ((\c@ExtensionConfig{..} -> (Map.lookup (mkKey publisher name lastUpdated) configsOldMap, c)) <$> configsNew)
        presentData = fromJust . fst <$> present
        missingConfigs = snd <$> missing
    Text.putStrLn [i|[Init] From #{showTarget target} have #{length presentData} extensions|]
    Text.putStrLn [i|[Init] From #{showTarget target} fetching #{length missingConfigs} extensions|]
    extDataQueue <- newTBMQueueIO queueCapacity
    extFailedConfigQueue <- newTBMQueueIO queueCapacity
    let extDataFile = mkTarget fetchedTmpDir
        extFailedConfigFile = mkTarget failedTmpDir
    concurrently_
      (extLogger extDataFile extFailedConfigFile extDataQueue extFailedConfigQueue)
      ( withTaskGroup nThreads $ \g -> do
          void (mapConcurrently g (usingLoggerT stdoutLog . getExtension target extDataQueue extFailedConfigQueue) missingConfigs)
          atomically $ closeTBMQueue extDataQueue
          atomically $ closeTBMQueue extFailedConfigQueue
      )
    extSorted :: [ExtensionData] <-
      DL.sortBy (\x y -> compare (mkKey x.publisher x.name x.lastUpdated) (mkKey y.publisher y.name y.lastUpdated))
        . (++ presentData)
        . fromRight []
        <$> Yaml.decodeFileEither extDataFile
    Yaml.encodeFile (mkTarget oldDir) extSorted
    T.writeFile [i|#{generatedDir}/#{targetNix}|] $ mkNixExtensions extSorted

main :: IO ()
main = do
  let
    dataDir = "data"
    nRepeat = 2
  replicateM_ nRepeat (main' dataDir 50 200 OpenVSX)
  replicateM_ nRepeat (main' dataDir 50 200 VSCodeMarketplace)

































































-- For dev purposes

-- main' VSCodeMarketplace 20

sample1 :: ByteString
sample1 =
  [i|
- a:
  - b: ""
    c:
    - d: e
|]

e1 :: ByteString -> Maybe Text
e1 x = (x & t) ^? nth 0 . key "a" . nth 0 . key "c" . nth 0 . key "d" . _String

t :: ByteString -> Value
t x = fromRight (String "bad") (decodeEither' x)

-- >>>t sample1
-- Array [Object (fromList [("a",Array [Object (fromList [("b",String ""),("c",Array [Object (fromList [("d",String "e")])])])])])]

-- >>>e1 sample1
-- Just "e"

e2 x = (x & t) ^? key "name"

-- >>>e2 sampleExtensions
-- Just [Object (fromList [("name",String "00-team-theme"),("publisher",String "i007c")]),Object (fromList [("name",String "000000"),("publisher",String "levminer")]),Object (fromList [("name",String "07Theme"),("publisher",String "flower607")]),Object (fromList [("name",String "0VN1"),("publisher",String "0VN1")]),Object (fromList [("name",String "0x0"),("publisher",String "willwung")]),Object (fromList [("name",String "1"),("publisher",String "2425370633")]),Object (fromList [("name",String "100-days-of-code-pack"),("publisher",String "thegeoffstevens")]),Object (fromList [("name",String "100-thieves-dark-theme"),("publisher",String "srteerra")]),Object (fromList [("name",String "10004ok"),("publisher",String "hyezoprk")]),Object (fromList [("name",String "101header"),("publisher",String "alexisvisco")])]

cs :: ByteString -> [ExtensionConfig]
cs x = fromRight [] (decodeEither' x)

e4 :: IO [ExtensionConfig]
e4 = fromRight [] <$> Yaml.decodeFileEither "data/new/vscode-marketplace.yaml"

e4l :: IO Int
e4l = length . Set.toList . Set.fromList . ((\ExtensionConfig{..} -> ([i|#{publisher}-#{name}-#{lastUpdated}|] :: Text)) <$>) <$> e4

e5e :: IO (Either Yaml.ParseException [ExtensionData])
e5e = Yaml.decodeFileEither "data/old/vscode-marketplace.yaml"

e5 :: IO [ExtensionData]
e5 = fromRight [] <$> Yaml.decodeFileEither "data/old/open-vsx.yaml"

e5l :: IO Int
e5l = length . Set.toList . Set.fromList . ((\ExtensionData{..} -> ([i|#{publisher}-#{name}-#{lastUpdated}|] :: Text)) <$>) <$> e5

e6 :: Value
e6 = t sampleExtensionsJson

-- >>>e6
-- Array [Object (fromList [("lastUpdated",String "2023-01-12T07:44:07.19Z"),("name",String "myhonor-h5-plugin"),("publisher",String "a30021955")])]

sampleExtensionsJson :: ByteString
sampleExtensionsJson =
  [i| 
[
{
"name": "myhonor-h5-plugin",
"publisher": "a30021955",
"lastUpdated": "2023-01-12T07:44:07.19Z"
}
]
|]

e3 :: [ExtensionConfig]
e3 = sampleExtensions & cs

-- >>>e3
-- [ExtensionConfig {name = "myhonor-h5-plugin", publisher = "_10021955", lastUpdated = 2023-01-12 07:44:07.19 UTC}]

sampleExtensions :: ByteString
sampleExtensions =
  [i|
- name: myhonor-h5-plugin
  publisher: _10021955
  lastUpdated: '2023-01-12T07:44:07.19Z'
|]

{-
nix-managed: JSONParseException Request {
  host                 = "marketplace.visualstudio.com"
  port                 = 443
  secure               = True
  requestHeaders       = [("Accept","application/json"),("Content-Type","application/json; charset=utf-8"),("Accept","application/json;api-version=6.1-preview.1")]
  path                 = "/_apis/public/gallery/extensionquery"
  queryString          = ""
  method               = "POST"
  proxy                = Nothing
  rawBody              = False
  redirectCount        = 10
  responseTimeout      = ResponseTimeoutDefault
  requestVersion       = HTTP/1.1
  proxySecureMode      = ProxySecureWithConnect
}
 (Response {responseStatus = Status {statusCode = 503, statusMessage = "Service Unavailable"}, responseVersion = HTTP/1.1, responseHeaders = [("Cache-Control","no-store"),("Content-Length","14084"),("Content-Type","text/html"),("X-Azure-ExternalError","0x80072ee2,OriginTimeout"),("X-MSEdge-Ref","Ref A: 982C003EFF8141B4BAAC55E94EA77381 Ref B: STOEDGE0922 Ref C: 2023-01-30T01:07:58Z"),("Date","Mon, 30 Jan 2023 01:08:17 GMT")], responseBody = (), responseCookieJar = CJ {expose = []}, responseClose' = ResponseClose, responseOriginalRequest = Request {
  host                 = "marketplace.visualstudio.com"
  port                 = 443
  secure               = True
  requestHeaders       = [("Accept","application/json"),("Content-Type","application/json; charset=utf-8"),("Accept","application/json;api-version=6.1-preview.1")]
  path                 = "/_apis/public/gallery/extensionquery"
  queryString          = ""
  method               = "POST"
  proxy                = Nothing
  rawBody              = False
  redirectCount        = 10
  responseTimeout      = ResponseTimeoutDefault
  requestVersion       = HTTP/1.1
  proxySecureMode      = ProxySecureWithConnect
}
}) (ParseError {errorContexts = [], errorMessage = "Failed reading: not a valid json value", errorPosition = 1:1 (0)})

-}

-- - name: myhonor-h5-plugin
--   publisher: 00021955
--   lastUpdated: '2023-01-12T07:44:07.19Z'

-- >>>t sampleExtensionData
-- Array [Object (fromList [("extensions",Array [Object (fromList [("deploymentType",Number 0.0),("displayName",String "Python"),("extensionId",String "f1f59ae4-9318-4f3c-a9b5-81b2eaa5f8a5"),("extensionName",String "python"),("flags",String "validated, public"),("lastUpdated",String "2023-01-27T10:28:38.573Z"),("publishedDate",String "2016-01-19T15:03:11.337Z"),("publisher",Object (fromList [("displayName",String "Microsoft"),("domain",String "https://microsoft.com"),("flags",String "verified"),("isDomainVerified",Bool True),("publisherId",String "998b010b-e2af-44a5-a6cd-0b5fd3b9b6f8"),("publisherName",String "ms-python")])),("releaseDate",String "2016-01-19T15:03:11.337Z"),("shortDescription",String "IntelliSense (Pylance), Linting, Debugging (multi-threaded, remote), Jupyter Notebooks, code formatting, refactoring, unit tests, and more."),("statistics",Array [Object (fromList [("statisticName",String "install"),("value",Number 7.5382929e7)]),Object (fromList [("statisticName",String "averagerating"),("value",Number 4.1866664886474609)]),Object (fromList [("statisticName",String "ratingcount"),("value",Number 525.0)]),Object (fromList [("statisticName",String "trendingdaily"),("value",Number 2.8532716789431262e-3)]),Object (fromList [("statisticName",String "trendingmonthly"),("value",Number 2.9802665149312264)]),Object (fromList [("statisticName",String "trendingweekly"),("value",Number 0.63693142759058452)]),Object (fromList [("statisticName",String "updateCount"),("value",Number 4.3846483e8)]),Object (fromList [("statisticName",String "weightedRating"),("value",Number 4.1907139323981486)]),Object (fromList [("statisticName",String "downloadCount"),("value",Number 768700.0)])]),("versions",Array [Object (fromList [("assetUri",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000"),("fallbackAssetUri",String "https://ms-python.gallery.vsassets.io/_apis/public/gallery/publisher/ms-python/extension/python/2023.1.10271009/assetbyname"),("files",Array [Object (fromList [("assetType",String "Microsoft.VisualStudio.Code.Manifest"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Code.Manifest")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.Content.Changelog"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Content.Changelog")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.Content.Details"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Content.Details")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.Content.License"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Content.License")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.Icons.Default"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Icons.Default")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.Icons.Small"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Icons.Small")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.VsixManifest"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.VsixManifest")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.VSIXPackage"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.VSIXPackage")]),Object (fromList [("assetType",String "Microsoft.VisualStudio.Services.VsixSignature"),("source",String "https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.VsixSignature")])]),("flags",String "validated"),("lastUpdated",String "2023-01-27T10:28:38.57Z"),("properties",Array [Object (fromList [("key",String "Microsoft.VisualStudio.Services.Branding.Color"),("value",String "#1e415e")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.Branding.Theme"),("value",String "dark")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.Links.Getstarted"),("value",String "https://github.com/Microsoft/vscode-python.git")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.Links.Support"),("value",String "https://github.com/Microsoft/vscode-python/issues")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.Links.Learn"),("value",String "https://github.com/Microsoft/vscode-python")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.Links.Source"),("value",String "https://github.com/Microsoft/vscode-python.git")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.Links.GitHub"),("value",String "https://github.com/Microsoft/vscode-python.git")]),Object (fromList [("key",String "Microsoft.VisualStudio.Code.Engine"),("value",String "^1.75.0-20230123")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.GitHubFlavoredMarkdown"),("value",String "true")]),Object (fromList [("key",String "Microsoft.VisualStudio.Code.ExtensionDependencies"),("value",String "")]),Object (fromList [("key",String "Microsoft.VisualStudio.Services.CustomerQnALink"),("value",String "https://github.com/microsoft/vscode-python/discussions/categories/q-a")]),Object (fromList [("key",String "Microsoft.VisualStudio.Code.ExtensionPack"),("value",String "ms-toolsai.jupyter,ms-python.vscode-pylance,ms-python.isort")]),Object (fromList [("key",String "Microsoft.VisualStudio.Code.LocalizedLanguages"),("value",String "")]),Object (fromList [("key",String "Microsoft.VisualStudio.Code.ExtensionKind"),("value",String "workspace,web")]),Object (fromList [("key",String "Microsoft.VisualStudio.Code.PreRelease"),("value",String "true")])]),("version",String "2023.1.10271009")])])])]),("pagingToken",Null),("resultMetadata",Array [Object (fromList [("metadataItems",Array [Object (fromList [("count",Number 1.0),("name",String "TotalCount")])]),("metadataType",String "ResultCount")])])])]

-- e4 = (t sampleExtensionData) ^? nth 0 . key "extensions" . nth 0 . key "versiions"

-- >>>e4

sampleExtensionData :: ByteString
sampleExtensionData =
  [i|
- extensions:
  - deploymentType: 0
    displayName: Python
    extensionId: f1f59ae4-9318-4f3c-a9b5-81b2eaa5f8a5
    extensionName: python
    flags: validated, public
    lastUpdated: 2023-01-27T10:28:38.573Z
    publishedDate: 2016-01-19T15:03:11.337Z
    publisher:
      displayName: Microsoft
      domain: https://microsoft.com
      flags: verified
      isDomainVerified: true
      publisherId: 998b010b-e2af-44a5-a6cd-0b5fd3b9b6f8
      publisherName: ms-python
    releaseDate: 2016-01-19T15:03:11.337Z
    shortDescription: IntelliSense (Pylance), Linting, Debugging (multi-threaded,
      remote), Jupyter Notebooks, code formatting, refactoring, unit tests, and more.
    statistics:
    - statisticName: install
      value: 7.5382929e7
    - statisticName: averagerating
      value: 4.1866664886474609
    - statisticName: ratingcount
      value: 525.0
    - statisticName: trendingdaily
      value: 2.8532716789431262e-3
    - statisticName: trendingmonthly
      value: 2.9802665149312264
    - statisticName: trendingweekly
      value: 0.63693142759058452
    - statisticName: updateCount
      value: 4.3846483e8
    - statisticName: weightedRating
      value: 4.1907139323981486
    - statisticName: downloadCount
      value: 768700.0
    versions:
    - assetUri: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000
      fallbackAssetUri: https://ms-python.gallery.vsassets.io/_apis/public/gallery/publisher/ms-python/extension/python/2023.1.10271009/assetbyname
      files:
      - assetType: Microsoft.VisualStudio.Code.Manifest
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Code.Manifest
      - assetType: Microsoft.VisualStudio.Services.Content.Changelog
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Content.Changelog
      - assetType: Microsoft.VisualStudio.Services.Content.Details
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Content.Details
      - assetType: Microsoft.VisualStudio.Services.Content.License
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Content.License
      - assetType: Microsoft.VisualStudio.Services.Icons.Default
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Icons.Default
      - assetType: Microsoft.VisualStudio.Services.Icons.Small
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.Icons.Small
      - assetType: Microsoft.VisualStudio.Services.VsixManifest
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.VsixManifest
      - assetType: Microsoft.VisualStudio.Services.VSIXPackage
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.VSIXPackage
      - assetType: Microsoft.VisualStudio.Services.VsixSignature
        source: https://ms-python.gallerycdn.vsassets.io/extensions/ms-python/python/2023.1.10271009/1674814982000/Microsoft.VisualStudio.Services.VsixSignature
      flags: validated
      lastUpdated: 2023-01-27T10:28:38.57Z
      properties:
      - key: Microsoft.VisualStudio.Services.Branding.Color
        value: '\#1e415e'
      - key: Microsoft.VisualStudio.Services.Branding.Theme
        value: dark
      - key: Microsoft.VisualStudio.Services.Links.Getstarted
        value: https://github.com/Microsoft/vscode-python.git
      - key: Microsoft.VisualStudio.Services.Links.Support
        value: https://github.com/Microsoft/vscode-python/issues
      - key: Microsoft.VisualStudio.Services.Links.Learn
        value: https://github.com/Microsoft/vscode-python
      - key: Microsoft.VisualStudio.Services.Links.Source
        value: https://github.com/Microsoft/vscode-python.git
      - key: Microsoft.VisualStudio.Services.Links.GitHub
        value: https://github.com/Microsoft/vscode-python.git
      - key: Microsoft.VisualStudio.Code.Engine
        value: ^1.75.0-20230123
      - key: Microsoft.VisualStudio.Services.GitHubFlavoredMarkdown
        value: 'true'
      - key: Microsoft.VisualStudio.Code.ExtensionDependencies
        value: ''
      - key: Microsoft.VisualStudio.Services.CustomerQnALink
        value: https://github.com/microsoft/vscode-python/discussions/categories/q-a
      - key: Microsoft.VisualStudio.Code.ExtensionPack
        value: ms-toolsai.jupyter,ms-python.vscode-pylance,ms-python.isort
      - key: Microsoft.VisualStudio.Code.LocalizedLanguages
        value: ''
      - key: Microsoft.VisualStudio.Code.ExtensionKind
        value: workspace,web
      - key: Microsoft.VisualStudio.Code.PreRelease
        value: 'true'
      version: 2023.1.10271009
  pagingToken: null
  resultMetadata:
  - metadataItems:
    - count: 1
      name: TotalCount
    metadataType: ResultCount
|]

-- need for buildVscodeMarketplaceExtension
-- name, publisher, version, src
-- name = "vscode-eslint";
-- publisher = "dbaeumer";
-- version = "2.3.3";
-- src = fetchurl {
--       url = "https://dbaeumer.gallery.vsassets.io/_apis/public/gallery/publisher/dbaeumer/extension/vscode-eslint/2.3.3/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage";
--       name = "vscode-eslint-2.3.3.zip";
--       sha256 = "sha256-T+EItTtiWw2GQEmYz8qkKl3jhC2mHwdP2XUt5/j6Ic8=";
--     };

-- q =

{- This code will be evaluated by ghcid
-- $> main

-- $> putStrLn "Hello from the magic comments!"

-- $> print (23 :: Int)
-}

{- This code will be evaluated by HLS
>>> 2 + 2
4
-}
