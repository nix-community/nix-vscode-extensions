{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImplicitParams #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}
{- FOURMOLU_DISABLE -}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}
{-# HLINT ignore "Redundant bracket" #-}
{-# HLINT ignore "Use lambda-case" #-}
{-# HLINT ignore "Use bimap" #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{- FOURMOLU_ENABLE -}

module Main (main) where

import Colog (LogAction, LoggerT, Message, Msg (..), Severity (..), WithLog, cfilter, fmtMessage, formatWith, logDebug, logError, logInfo, logTextStdout, usingLoggerT)
import Colog.Concurrent (defCapacity, withBackgroundLogger)
import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (forConcurrently, mapConcurrently_)
import Control.Concurrent.Async.Pool (mapConcurrently, withTaskGroup)
import Control.Concurrent.STM (STM, TMVar, TVar, atomically, newTMVarIO, newTVarIO, putTMVar, readTVar, readTVarIO, takeTMVar, tryReadTMVar, writeTVar)
import Control.Concurrent.STM.TBMQueue (TBMQueue, closeTBMQueue, newTBMQueueIO, peekTBMQueue, tryReadTBMQueue, writeTBMQueue)
import Control.Lens (Bifunctor (bimap), Field1 (_1), Prism', Suffixed (suffixed), Traversal', filtered, indexing, itraversed, non, prism', reindexed, review, selfIndex, to, traversed, (%~), (+~), (<&>), (<.), (^.), (^..), (^?), (^@..), _2, _Just)
import Control.Monad (replicateM_, unless, void, when)
import Control.Monad.IO.Class (MonadIO (..))
import Data.Aeson (FromJSON (..), Options (constructorTagModifier, unwrapUnaryRecords), ToJSON (toJSON), Value (..), defaultOptions, eitherDecodeFileStrict', encode, genericParseJSON, genericToJSON, withObject, (.:), (.:?))
import Data.Aeson.Lens (key, nth, _Array, _Integer, _String)
import Data.Aeson.Types (parseFail, parseMaybe)
import Data.ByteString qualified as BS
import Data.Either (fromRight, isLeft)
import Data.Foldable (traverse_)
import Data.Function (fix, (&))
import Data.Generics.Labels ()
import Data.HashMap.Strict qualified as Map
import Data.HashSet qualified as Set
import Data.Hashable (Hashable)
import Data.List (partition)
import Data.List qualified as DL
import Data.Maybe (fromJust, isJust, isNothing)
import Data.String (IsString (fromString))
import Data.String.Interpolate (i)
import Data.Text (Text, pack, strip, unpack)
import Data.Text qualified as Text
import Data.Text.Lazy qualified as T
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import GHC.IO.Handle (BufferMode (NoBuffering), Handle, hSetBuffering)
import GHC.IO.IOMode (IOMode (AppendMode, WriteMode))
import Network.HTTP.Client (Response (..), responseTimeoutMicro)
import Network.HTTP.Client.Conduit (Request (method))
import Network.HTTP.Simple (httpJSONEither, setRequestBodyJSON, setRequestHeaders, setRequestResponseTimeout)
import Network.HTTP.Types (status200)
import System.Environment (getEnv)
import System.IO (stdout, withFile)
import Text.Pretty.Simple (defaultOutputOptionsNoColor, pShowOpt)
import Turtle (Alternative (empty), mktree, rm, shellStrictWithErr, testfile)
import UnliftIO.Exception

-- | Possible targets
data Target = VSCodeMarketplace | OpenVSX deriving (Eq)

newtype Name = Name {_name :: Text}
  deriving newtype (IsString, Eq, Ord, Hashable)
  deriving (Generic)

newtype Publisher = Publisher {_publisher :: Text}
  deriving newtype (IsString, Eq, Ord, Hashable)
  deriving (Generic)

newtype LastUpdated = LastUpdated {_lastUpdated :: UTCTime}
  deriving newtype (Eq, Ord, Hashable, Show)
  deriving (Generic)

newtype Version = Version {_version :: Text}
  deriving newtype (IsString, Eq, Ord, Hashable)
  deriving (Generic)

aesonOptions :: Options
aesonOptions = defaultOptions{unwrapUnaryRecords = True}

instance Show Name where show = Text.unpack . _name
instance FromJSON Name where parseJSON = genericParseJSON aesonOptions
instance ToJSON Name where toJSON = genericToJSON aesonOptions
instance Show Publisher where show = Text.unpack . _publisher
instance FromJSON Publisher where parseJSON = genericParseJSON aesonOptions
instance ToJSON Publisher where toJSON = genericToJSON aesonOptions
instance FromJSON LastUpdated where parseJSON = genericParseJSON aesonOptions
instance ToJSON LastUpdated where toJSON = genericToJSON aesonOptions
instance Show Version where show = Text.unpack . _version
instance FromJSON Version where parseJSON = genericParseJSON aesonOptions
instance ToJSON Version where toJSON = genericToJSON aesonOptions

-- | A simple config that is enough to fetch an extension
data ExtensionConfig = ExtensionConfig
  { name :: Name
  , publisher :: Publisher
  , lastUpdated :: LastUpdated
  , version :: Version
  , platform :: Platform
  , missingTimes :: Int
  }
  deriving (Generic, FromJSON, ToJSON, Show, Eq, Hashable)

-- | Full necessary info about an extension
data ExtensionInfo = ExtensionInfo
  { name :: Name
  , publisher :: Publisher
  , lastUpdated :: LastUpdated
  , version :: Version
  , sha256 :: Text
  , platform :: Platform
  , missingTimes :: Int
  -- ^ how many times the extension could not be fetched
  }
  deriving (Generic, FromJSON, ToJSON, Show)

-- universal
--

-- | Select a base API URL depending on the target
apiUrl :: Target -> String
apiUrl target =
  targetSelect
    target
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    "https://open-vsx.org/api"

-- | Select an action depending on a target
targetSelect :: Target -> p -> p -> p
targetSelect target f g =
  case target of
    VSCodeMarketplace -> f
    OpenVSX -> g

-- | Convert a target to a string
showTarget :: Target -> String
showTarget target = targetSelect target "vscode-marketplace" "open-vsx"

-- | Handle the case when we need to write the first list of extensions' info into a file
encodeFirstList :: ToJSON a => Handle -> [a] -> IO ()
encodeFirstList h (x : xs) = BS.hPutStr h ([i|#{encode x}\n|]) >> traverse_ (\y -> BS.hPutStr h ([i|, #{encode y}\n|])) xs
encodeFirstList _ _ = error "Please, check the pattern matching at where you call this function"

-- | Read everything from a queue into a list
-- without retrying (sleeping if a queue is empty)
--
-- this is to allow faster reading of a queue
flushTBMQueue :: TBMQueue a -> STM (Maybe [a])
flushTBMQueue q = flip fix [] $ \ret contents -> do
  s <- tryReadTBMQueue q
  case s of
    Just (Just a) -> ret (a : contents)
    Nothing -> pure Nothing
    _ -> pure $ pure contents

-- | Log info about extensions from a queue into a file
extLogger :: ToJSON a => FilePath -> TBMQueue a -> IO ()
extLogger file queue =
  withFile file AppendMode $ \h ->
    do
      -- let the logs go straight to a file
      hSetBuffering h NoBuffering
      -- write the initial symbol
      BS.hPutStr h "[ "
      -- if it's the first time we write into a file,
      -- we should correctly handle commas
      -- so, we introduce a flag
      flip fix True $ \ret isFirst ->
        do
          -- this is to make logger sleep when there's no data in the queue
          _ <- atomically $ peekTBMQueue queue
          -- read everything from a queue into a list
          extData <- atomically $ flushTBMQueue queue
          if isFirst
            then
              traverse_
                ( \case
                    -- handle the case when it's the first write
                    -- but the queue is empty
                    [] -> ret True
                    -- handle another case
                    xs -> encodeFirstList h xs
                )
                extData
            else -- next time, we can write all values from the list in the same way
              traverse_ (traverse_ (\x -> BS.hPutStr h [i|, #{encode x}\n|])) extData
          -- this type of queue may become `closed`
          -- in this case, values that we read from it will be `Nothing`
          -- unless such a situation happens, we need to repeat our loop
          unless (isNothing extData) (ret False)
      -- even if this logger thread is killed by an exception,
      -- we want the opened file to store a valid JSON.
      -- so, we append a closing bracket
      `finally` BS.hPutStr h "]"

-- | Log info about the number of processed extensions
processedLogger :: AppConfigImpl => Int -> TMVar Int -> LoggerT Message IO ()
processedLogger total processed = flip fix 0 $ \ret n -> do
  p <- liftIO $ atomically $ tryReadTMVar processed
  traverse_
    ( \cnt -> do
        when (cnt /= n) $ logInfo [i|#{INFO} Processed (#{cnt}/#{total}) extensions|]
        liftIO $ threadDelay ?_PROCESSED_LOGGER_DELAY
        ret cnt
    )
    p

-- types for constructing a request to VSCode Marketplace
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

-- | Compose a body of a request about an extension to VSCode Marketplace
requestExtensionBodyVSCodeMarketplace :: Text -> Req
requestExtensionBodyVSCodeMarketplace name_ =
  Req
    { filters =
        [ Filter
            { criteria =
                [ Criterion{filterType = 8, value = "Microsoft.VisualStudio.Code"}
                , Criterion{filterType = 7, value = name_}
                , Criterion{filterType = 12, value = "4096"}
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

-- platform of an extension
data Platform
  = -- | universal extensions should have the lowest order
    PUniversal
  | PLinux_x64
  | PLinux_arm64
  | PDarwin_x64
  | PDarwin_arm64
  deriving (Generic, Eq, Hashable, Ord)

instance FromJSON Platform where
  parseJSON (String s) =
    case s ^? _Platform of
      Just s' -> pure s'
      Nothing -> parseFail "Could not parse platform"
  parseJSON _ = parseFail "Expected a string"

instance ToJSON Platform where
  toJSON :: Platform -> Value
  toJSON = String . review _Platform

_Platform :: Prism' Text Platform
_Platform = prism' embed_ match_
 where
  embed_ :: Platform -> Text
  embed_ = \case
    PUniversal -> "universal"
    PLinux_x64 -> "linux-x64"
    PLinux_arm64 -> "linux-arm64"
    PDarwin_x64 -> "darwin-x64"
    PDarwin_arm64 -> "darwin-arm64"
  match_ :: Text -> Maybe Platform
  match_ x
    | x == embed_ PUniversal = Just PUniversal
    | x == embed_ PLinux_x64 = Just PLinux_x64
    | x == embed_ PLinux_arm64 = Just PLinux_arm64
    | x == embed_ PDarwin_x64 = Just PDarwin_x64
    | x == embed_ PDarwin_arm64 = Just PDarwin_arm64
    | otherwise = Nothing

instance Show Platform where
  show :: Platform -> String
  show = show . unpack . review _Platform

-- | Get an extension from a target site and pass info about it to other threads
--
-- We do this by using the thread-safe data structures like special queues and vars
getExtension :: AppConfigImpl => Target -> TBMQueue ExtensionInfo -> TBMQueue ExtensionConfig -> TMVar Int -> TVar Int -> ExtensionConfig -> LoggerT Message IO ()
getExtension target extInfoQueue extFailedConfigQueue extProcessedN extFailedN extConfig@ExtensionConfig{platform, lastUpdated, missingTimes} = do
  let
    -- select an action for a target
    publisher = extConfig.publisher & #_publisher %~ Text.toLower
    name = extConfig.name & #_name %~ Text.toLower
    select = targetSelect target
    extName = [i|#{publisher}.#{name}|] :: Text
    -- prepare a request depending on the target site
    request =
      setRequestResponseTimeout (responseTimeoutMicro ?_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT) $
        select
          ( setRequestBodyJSON (requestExtensionBodyVSCodeMarketplace extName) $
              setRequestHeaders
                [ ("Accept", "application/json; api-version=6.1-preview.1")
                , ("Content-Type", "application/json")
                ]
                [i|#{apiUrl VSCodeMarketplace}|]{method = "POST"}
          )
          ( setRequestHeaders
              [ ("Accept", "application/json")
              , ("Content-Type", "application/json")
              ]
              $ [i|#{apiUrl OpenVSX}/#{publisher}/#{name}|]{method = "GET"}
          )
  logDebug [i|#{START} Requesting info about #{extName} from #{ppTarget target}|]
  -- a request may be unsuccessful, so we `try` to catch the error and don't let it kill the app
  response_ <- liftIO $ try @_ @SomeException $ httpJSONEither request
  case response_ of
    -- if we catch an error
    Left err -> logDebug [i|#{FAIL} Requesting info about #{extName} from #{ppTarget target}. The error:\n #{err}|]
    Right response -> do
      isFailed <-
        -- if a request is unsuccessful in another way
        if responseStatus response /= status200 || isLeft (responseBody response)
          then do
            logDebug [i|#{FAIL} Requesting info about #{extName} from #{ppTarget target}. Server response:\n #{response}|]
            pure True
          else do
            -- if we successfully got the response body, it should contain a JSON value
            let body :: Value = fromRight undefined (responseBody response)
                -- depending on the target site, we use an appropriate way to extract a version from that JSON value
                extVersion =
                  Version
                    <$> select
                      (body ^? key "results" . nth 0 . key "extensions" . nth 0 . key "versions" . nth 0 . key "version" . _String)
                      (body ^? key "version" . _String)
            -- if we can't extract the version info
            if isNothing extVersion
              then do
                logDebug $
                  [i|#{FAIL} Getting the version of #{extName}.|]
                    <> ( -- on VSCode marketplace, if there's no info about an extension,
                         -- the `results.extensions` value of a body will be an empty array
                         if target == VSCodeMarketplace && (null (body ^.. key "results" . nth 0 . key "extensions" . _Array . traversed))
                          then [i| #{ppTarget target} doesn't provide info about this extension.|]
                          else mempty
                       )
                pure True
              else do
                -- we got the version info
                let version = fromJust extVersion
                    -- and can prepare a url for a target site
                    url :: Text
                    url =
                      select
                        ( let platform' :: Text =
                                ( case platform of
                                    PUniversal -> ""
                                    x -> [i|targetPlatform=#{x}|]
                                )
                           in [i|https://#{publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/#{publisher}/extension/#{name}/#{version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?#{platform'}|]
                        )
                        ( let platform' :: Text =
                                ( case platform of
                                    PUniversal -> ""
                                    x -> [i|@#{x}|]
                                )
                           in [i|https://open-vsx.org/api/#{publisher}/#{name}/#{version}/file/#{extName}-#{version}#{platform'}.vsix|]
                        )
                logDebug [i|#{START} Fetching #{extName} from #{url}|]
                -- and let nix fetch a file from that url into nix/store
                -- nix produces a SHA (we extract it via `jq`)
                let timeout' = ?_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT `div` _MICROSECONDS
                (_, strip -> sha256, errText) <- shellStrictWithErr [i|nix store prefetch-file --timeout #{timeout'} --json #{url} | jq -r .hash|] empty
                -- if stderr was non-empty, there was an error
                if not (Text.null errText)
                  then do
                    logDebug [i|#{FAIL} Fetching #{extName} from #{url}. The stderr:\n#{errText}|]
                    pure True
                  else do
                    logInfo [i|#{FINISH} Fetching extension #{extName} from #{url}|]
                    -- when everything is ok, we write the extension info into a queue
                    -- this is to let other threads read from it
                    liftIO $ atomically $ writeTBMQueue extInfoQueue $ ExtensionInfo{..}
                    pure False
      -- if at some point we failed to obtain an extension's info,
      -- we write its config into a queue for failed configs
      when isFailed do
        liftIO $ atomically $ writeTBMQueue extFailedConfigQueue extConfig
        liftIO $ atomically $ readTVar extFailedN >>= \x -> writeTVar extFailedN (x + 1)
  -- when finished, we update a shared counter
  liftIO $ atomically $ takeTMVar extProcessedN >>= \x -> putTMVar extProcessedN (x + 1)

-- | Config of a fetcher
data FetcherConfig a = FetcherConfig
  { target :: Target
  , nThreads :: Int
  , queueCapacity :: Int
  , extConfigs :: [ExtensionConfig]
  , cacheDir :: FilePath
  , mkTargetJSON :: FilePath -> FilePath
  , logger :: LogAction a Message
  , tmpDir :: FilePath
  }

-- | Fetch the extensions given their configurations
runFetcher :: AppConfigImpl => FetcherConfig IO -> IO ()
runFetcher FetcherConfig{..} = do
  let fetchedTmpDir :: FilePath = [i|#{tmpDir}/fetched|]
      failedTmpDir :: FilePath = [i|#{tmpDir}/failed|]
  -- if don't exist, we create the directories for files with fetched, failed, and cached extensions
  traverse_ (\x -> mktree [i|#{x}|]) [fetchedTmpDir, failedTmpDir, cacheDir]
  -- if there were previous files with given names, we remove them
  traverse_ (\x -> let f = [i|#{mkTargetJSON x}|] in testfile f >>= (`when` rm f)) [fetchedTmpDir, failedTmpDir]

  let
    logInfo_ = usingLoggerT logger . logInfo
    logError_ = usingLoggerT logger . logError
    extensionInfoCachedJSON = mkTargetJSON cacheDir

  -- if there is a file with cached info, we read it into a list
  extensionInfoCached <-
    ( eitherDecodeFileStrict' extensionInfoCachedJSON
        >>= \case
          Left err -> logError_ (pack $ show err) >> pure []
          Right v -> pure v
      )
      `catchAny` (\err -> logError_ (pack $ show err) >> pure [])

  let mkKey :: Publisher -> Name -> Platform -> LastUpdated -> (Publisher, Name, Platform, LastUpdated)
      mkKey publisher name platform lastUpdated = (publisher, name, platform, lastUpdated)
      -- [i|#{publisher}-#{name}-#{platform}-#{lastUpdated}|]
      mkKeyInfo ExtensionInfo{..} = mkKey publisher name platform lastUpdated
      mkKeyConfig ExtensionConfig{..} = mkKey publisher name platform lastUpdated
      -- we load the cached info into a map for quicker access
      extensionInfoCacheMap = Map.fromList ((\d -> (mkKeyInfo d, d)) <$> extensionInfoCached)
      -- also, we filter out the duplicates among the extension configs
      configsSorted = Set.toList . Set.fromList $ extConfigs
      -- we partition the extension configs depending on if they're present in a cache
      (presentExtensionInfo, extensionConfigsMissing) =
        (partition (isJust . fst) ((\c -> (Map.lookup (mkKeyConfig c) extensionInfoCacheMap, c)) <$> configsSorted))
          & bimap (fromJust . fst <$>) (snd <$>)
      -- the extension info that are present according to a response
      extensionInfoPresentMap = Map.fromList ((\d -> (mkKeyInfo d, d)) <$> presentExtensionInfo)
      -- extension info that are missing according to a response
      -- the missing counter is incremented
      extensionInfoMissing =
        (partition (\c -> isNothing $ Map.lookup (mkKeyInfo c) extensionInfoPresentMap) extensionInfoCached)
          ^.. _1 . traversed . filtered (\c -> c.missingTimes + 1 < ?_MAX_MISSING_TIMES)
          & traversed . #missingTimes +~ 1
      -- these missing info are turned into configs so that they can be fetched again
      -- this conversion preserves the missing times counter
      extensionInfoMissingConfigs = extensionInfoMissing <&> (\ExtensionInfo{..} -> ExtensionConfig{..})
      -- combine new and old missing configs
      extensionConfigsMissing' = extensionConfigsMissing <> extensionInfoMissingConfigs
      -- and calculate the number of the configs of extensions that are missing
      numberExtensionConfigsMissing = length extensionConfigsMissing'
  -- collect extensions from cache that are not present
  logInfo_ [i|From #{ppTarget target} have #{length extensionInfoCached} cached extensions|]
  logInfo_ [i|There are #{length extensionConfigsMissing} new extension configs.|]
  logInfo_ [i|From #{length extensionInfoCached} cached extensions, #{length extensionInfoMissing} are not among the extensions available at #{ppTarget target}.|]
  logInfo_ [i|#{START} Updating cached info about #{numberExtensionConfigsMissing} extension(s) from #{ppTarget target}|]

  -- we prepare the shared queues and variables
  extInfoQueue <- newTBMQueueIO queueCapacity
  extFailedConfigQueue <- newTBMQueueIO queueCapacity
  -- this is a counter of processed extensions
  -- it should become empty when all extensions are processed
  extProcessedN <- newTMVarIO 0
  extProcessedNFinal <- newTVarIO 0
  extFailedN <- newTVarIO 0
  -- as well as file names where threads will write to
  let fetchedExtensionInfoFile = mkTargetJSON fetchedTmpDir
      failedExtensionConfigFile = mkTargetJSON failedTmpDir

  -- and run together
  ( mapConcurrently_
      id
      [ -- a logger of info about the number of successfully processed extensions
        (usingLoggerT logger $ processedLogger numberExtensionConfigsMissing extProcessedN)
      , -- a logger that writes the info about successfully fetched extensions into a file
        (extLogger fetchedExtensionInfoFile extInfoQueue)
      , -- a logger that writes the info about failed extensions into a file
        (extLogger failedExtensionConfigFile extFailedConfigQueue)
      , -- and an action that uses a thread pool to fetch the extensions
        -- it's more efficient than spawning a thread per each element of a list with extensions' configs
        ( withTaskGroup nThreads $ \g -> do
            void
              ( mapConcurrently
                  g
                  (usingLoggerT logger . (getExtension target extInfoQueue extFailedConfigQueue extProcessedN extFailedN))
                  extensionConfigsMissing'
              )
            -- when all configs are processed, we need to close both queues
            -- this will let loggers know that they should quit
            atomically $ closeTBMQueue extInfoQueue
            atomically $ closeTBMQueue extFailedConfigQueue
            -- make this var empty to notify the threads reading from it
            -- clone its value
            atomically $ takeTMVar extProcessedN >>= writeTVar extProcessedNFinal
        )
      ]
    )
    -- even if there are some errors
    -- we want to finally append the info about the newly fetched extensions to the cache
    `finally` do
      logInfo_ [i|#{START} Caching updated info about extensions from #{ppTarget target}|]
      -- we combine into a sorted list the cached info and the new info that we read from a file
      extSorted <-
        DL.sortBy (\x y -> compare (mkKeyInfo x) (mkKeyInfo y))
          . (<> presentExtensionInfo)
          . fromRight []
          <$> eitherDecodeFileStrict' fetchedExtensionInfoFile
      -- after that, we compactly write the extensions info

      withFile extensionInfoCachedJSON WriteMode $ \h -> do
        BS.hPutStr h "[ "
        case extSorted of
          [] -> pure ()
          xs -> encodeFirstList h xs
        BS.hPutStr h "]"
      logInfo_ [i|#{FINISH} Caching updated info about extensions from #{ppTarget target}|]
      extProcessedNFinal' <- readTVarIO extProcessedNFinal
      extFailedN' <- readTVarIO extFailedN
      logInfo_ [i|Processed #{extProcessedNFinal'}, failed #{extFailedN'} extensions|]

-- | Retry an action a given number of times with a given delay and log about its status
retry_ :: (MonadIO m, WithLog env Message m, Monoid b, AppConfigImpl) => (Int -> m b) -> Int -> Text -> Text -> m b
retry_ ret n msg msgTryExtra =
  if n > 0
    then logDebug [i|#{FAIL} Attempt #{n}. #{msg}. #{msgTryExtra}|] >> liftIO (threadDelay ?_RETRY_DELAY) >> ret (n - 1)
    else logDebug [i|#{ABORT} #{msg}|] >> pure mempty

-- | Possible action statuses
--
-- used in logs
data ActionStatus = INFO | START | FAIL | ABORT | FINISH

instance Show ActionStatus where
  show :: ActionStatus -> String
  show d =
    let
      repr :: ActionStatus -> String
      repr e = case e of
        INFO -> "INFO"
        START -> "START"
        FAIL -> "FAIL"
        ABORT -> "ABORT"
        FINISH -> "FINISH"
      width = maximum $ length . repr <$> [INFO, START, FAIL, ABORT, FINISH]
     in
      (\x -> [i|[ #{x <> (replicate (width - length x) ' ') } ]|]) (repr d)

ppTarget :: Target -> Text
ppTarget x = targetSelect x "VSCode Marketplace" "Open VSX"

extFlagsAllowed :: [Text]
extFlagsAllowed = ["validated", "public", "preview", "verified"]

filteredByFlags :: Traversal' Value Value
filteredByFlags =
  filtered
    ( \y ->
        maybe
          False
          -- check if all flags are allowed
          (\z -> length (Text.splitOn ", " z) == length ((Text.splitOn ", " z) & DL.intersect extFlagsAllowed))
          (y ^? key "flags" . _String)
    )

-- | Get a list of extension configs from VSCode Marketplace
getConfigsVSCodeMarketplace :: AppConfigImpl => Int -> LoggerT Message IO (Maybe [ExtensionConfig])
getConfigsVSCodeMarketplace nRetry = flip fix nRetry $ \ret (nRetry_ :: Int) -> do
  let
    pageCount = ?_VSCODE_MARKETPLACE_PAGE_COUNT
    pageSize = ?_VSCODE_MARKETPLACE_PAGE_SIZE
    target = VSCodeMarketplace
    requestExtensionsList pageNumber =
      Req
        { filters =
            [ Filter
                { criteria = [Criterion{filterType = 8, value = "Microsoft.VisualStudio.Code"}, Criterion{filterType = 12, value = "4096"}]
                , sortBy = 4
                , sortOrder = 2
                , ..
                }
            ]
        , assetTypes = []
        , flags = 946
        }
  logInfo [i|#{START} Collecting #{pageCount} page(s) of size #{pageSize}.|]
  -- we request the pages of extensions from VSCode Marketplace concurrently
  pages <-
    ( traverse responseBody
        <$> liftIO
          ( forConcurrently
              [1 .. pageCount]
              ( \pageNumber ->
                  do
                    httpJSONEither @_ @Value
                      $ setRequestBodyJSON (requestExtensionsList pageNumber)
                      $ setRequestHeaders
                        [ ("CONTENT-TYPE", "application/json")
                        , ("ACCEPT", "application/json; api-version=6.1-preview.1")
                        , ("ACCEPT-ENCODING", "gzip")
                        ]
                      $ (fromString (apiUrl target)){method = "POST"}
              )
          )
      )
  case pages of
    -- if we were unsuccessful, we need to retry
    Left l -> retry_ ret (nRetry - nRetry_ + 1) [i|Getting info about extensions from #{ppTarget target}|] [i|#{l}|]
    Right r -> do
      let configs =
            -- we'll turn each page into a list of extension configs, concatenate them and return
            r
              ^@.. traversed
              . key "results"
              . nth 0
              . key "extensions"
              . _Array
              . traversed
              . filteredByFlags
              . to
                ( \k ->
                    parseMaybe
                      ( withObject [i|Extension|] $ \o -> do
                          name :: Name <- o .: "extensionName"
                          publisher :: Publisher <- o .: "publisher" >>= \x -> x .: "publisherName"
                          pure ((name, publisher), k)
                      )
                      k
                )
              . _Just
              . (reindexed fst selfIndex)
              <. indexing _2
              <. indexing (key "versions")
              <. indexing _Array
              <. itraversed
              ^.. traversed
              . to
                ( \(k, v) ->
                    parseMaybe
                      ( withObject [i|Extension version|] $ \o -> do
                          lastUpdated <- o .: "lastUpdated"
                          version <- o .: "version"
                          platform <- o .:? "targetPlatform" <&> (^. non PUniversal)
                          let (name, publisher) = k
                              -- for now, the configs are fresh
                              missingTimes = 0
                          pure ExtensionConfig{..}
                      )
                      v
                )
              . _Just
      -- logInfo $ pShow' configs
      pure . pure $ configs

-- | Get a list of extension configs from Open VSX
getConfigsOpenVSX :: AppConfigImpl => Int -> LoggerT Message IO (Maybe [ExtensionConfig])
getConfigsOpenVSX nRetry = flip fix nRetry $ \retryInfo (nRetryInfo :: Int) -> do
  let
    target = OpenVSX
    baseURL = apiUrl target
    ppTarget_ = ppTarget target
  -- we send a request to get the total number of extions on Open VSX
  extInfo <- httpJSONEither @_ @Value [i|#{baseURL}/-/search?size=1|]{method = "GET"}
  if responseStatus extInfo /= status200 || isLeft (responseBody extInfo)
    then -- if there're problems, we'll repeat the previous actions
      retry_ retryInfo (nRetry - nRetryInfo + 1) [i|Getting the extensions' info from #{ppTarget_}|] [i|Got: #{responseBody extInfo}|]
    else do
      -- we need to get the extension count from the request
      let extCount = fromRight undefined (responseBody extInfo) ^? key "totalSize" . _Integer
      if isNothing extCount
        then logDebug [i|#{FAIL} Getting the extension count from #{ppTarget_}. Perhaps you need to check the API request. |] >> pure mempty
        else -- then, several times, we try to get the extensions
        flip fix nRetry $ \retryList nRetryList -> do
          let
            count = fromJust extCount
          logInfo [i|#{FINISH} Getting the extension count from #{ppTarget_}. There are #{count} extensions (including the platform-specific ones).|]
          let
            req =
              setRequestResponseTimeout (responseTimeoutMicro ?_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT)
                $ setRequestHeaders
                  [ ("CONTENT-TYPE", "application/json")
                  , ("ACCEPT", "application/json; api-version=6.1-preview.1")
                  , ("ACCEPT-ENCODING", "gzip")
                  ]
                $ [i|#{baseURL}/-/search?includeAllVersions=false&size=#{count}|]{method = "GET"}
          logInfo [i|#{START} Getting the extensions from #{ppTarget target}|]
          extListResp <- liftIO $ tryAny (httpJSONEither @_ @Value req)
          case extListResp of
            -- if there are any exceptions, we'll retry
            Left err -> retry_ retryList (nRetry - nRetryList + 1) [i|Requesting the extensions list from #{ppTarget target}|] [i|#{err}|]
            Right extListResp_ ->
              if responseStatus extListResp_ /= status200 || isLeft (responseBody extListResp_)
                then retry_ retryList (nRetry - nRetryList + 1) [i|Getting extension list from #{ppTarget_}|] [i|Got: #{responseBody extListResp_}|]
                else do
                  -- if everything was ok, we extract the list of the values that correspond to extensions
                  -- from the response
                  let extList = (fromRight undefined (responseBody extListResp_))
                  -- logInfo $ pShow' extList
                  pure . pure $
                    extList
                      ^@.. key "extensions"
                      . _Array
                      . traversed
                      . to
                        -- we parse the values to obtain the extension configs
                        ( \k ->
                            parseMaybe
                              ( withObject [i|Extension|] $ \o -> do
                                  name :: Name <- o .: "name"
                                  publisher :: Publisher <- o .: "namespace"
                                  lastUpdated :: LastUpdated <- o .: "timestamp"
                                  version :: Version <- o .: "version"
                                  pure ((name, publisher, lastUpdated, version), k)
                              )
                              k
                        )
                      . _Just
                      . reindexed fst selfIndex
                      <. indexing _2
                      <. indexing (key "files")
                      <. indexing (key "download")
                      <. indexing _String
                      <. indexing (suffixed ".vsix")
                      -- platform-specific extensions have a download link like "https://open-vsx.org/api/astro-build/astro-vscode/win32-x64/0.29.5/file/astro-build.astro-vscode-0.29.5@win32-x64.vsix"
                      <. indexing (to (Text.dropWhile (== '@') . Text.dropWhile (/= '@')))
                      <. indexing (to (\x -> if Text.null x then Just PUniversal else x ^? _Platform))
                      <. _Just
                      ^.. traversed
                      . to (\((name, publisher, lastUpdated, version), platform) -> ExtensionConfig{missingTimes = 0, ..})

-- | Config for a crawler
data CrawlerEnv a = CrawlerEnv
  { target :: Target
  , nRetry :: Int
  , logger :: LogAction a Message
  }

-- | Run a crawler depending on the target site to (hopefully) get the extension configs
runCrawler :: AppConfigImpl => CrawlerEnv IO -> IO (Maybe [ExtensionConfig])
runCrawler CrawlerEnv{..} =
  usingLoggerT logger do
    logInfo [i|#{START} Updating info about extensions from #{ppTarget target}.|]
    -- we select the target crawler and run it
    configs <- targetSelect target getConfigsVSCodeMarketplace getConfigsOpenVSX nRetry
    -- we normalize the configs by lowercasing the extension name and publisher
    let configsNormalized = ((\ExtensionConfig{..} -> ExtensionConfig{name = name & #_name %~ Text.toLower, publisher = publisher & #_publisher %~ Text.toLower, ..}) <$>) <$> configs
    logInfo [i|#{FINISH} Updating info about extensions from #{ppTarget target}.|]
    -- finally, we return the configs
    pure configsNormalized

data ProcessTargetEnv = ProcessTargetEnv
  { target :: Target
  , nThreads :: Int
  , queueCapacity :: Int
  , dataDir :: FilePath
  , logger :: LogAction IO Message
  }

pShow' :: Show a => a -> Text
pShow' = T.toStrict . pShowOpt defaultOutputOptionsNoColor

processTarget :: AppConfigImpl => ProcessTargetEnv -> IO ()
processTarget ProcessTargetEnv{..} =
  do
    let
      cacheDir :: FilePath = [i|#{dataDir}/cache|]
      tmpDir :: FilePath = [i|#{dataDir}/tmp|]

      targetJSON :: FilePath = [i|#{showTarget target}.json|]
      mkTargetJSON :: FilePath -> FilePath
      mkTargetJSON x = [i|#{x}/#{targetJSON}|]

      nRetry = ?_N_RETRY

    -- we first run a crawler to get the extension configs
    extConfigs_ <- runCrawler CrawlerEnv{..}
    -- if we got them, we'll run a fetcher
    traverse_ (\extConfigs -> runFetcher FetcherConfig{..}) extConfigs_
    -- in case of errors
    `catchAny` \x -> (usingLoggerT logger $ logError [i|Got an exception when requesting #{ppTarget target}:\n #{x}|])

_CONFIG_ENV_VAR :: String
_CONFIG_ENV_VAR = "CONFIG"

data AppConfig = AppConfig
  { runN :: Maybe Int
  -- ^ Times to process a target site
  , processedLoggerDelay :: Maybe Int
  -- ^ Seconds to wait for a logger of info about processed extensions until logging again
  , retryDelay :: Maybe Int
  -- ^ Seconds to wait before retrying
  , openVsxRequestResponseTimeout :: Maybe Int
  -- ^ Seconds to wait until Open VSX returns a response
  , vscodeMarketplacePageSize :: Maybe Int
  -- ^ Number of xtensions per a page to request from VSCode Marketplace
  , vscodeMarketplacePageCount :: Maybe Int
  -- ^ Number of extension pages to request from VSCode Marketplace
  , nRetry :: Maybe Int
  -- ^ Number of times to retry an action
  , logSeverity :: Maybe MySeverity
  -- ^ Log severity level
  , dataDir :: Maybe FilePath
  -- ^ Data directory
  , nThreadsVSCodeMarketplace :: Maybe Int
  -- ^ Number of threads to use for fetching from VSCode Marketplace
  , nThreadsOpenVSX :: Maybe Int
  -- ^ Number of threads to use for fetching from Open VSX
  , queueCapacity :: Maybe Int
  -- ^ Max number of elements to store in a queue
  , maxMissingTimes :: Maybe Int
  -- ^ Max number of times an extension may be missing before it's removed from cache
  }
  deriving (Generic, FromJSON)

data MySeverity = SDebug | SInfo | SWarning | SError deriving (Generic, Eq)

instance FromJSON MySeverity where
  parseJSON = genericParseJSON (defaultOptions{constructorTagModifier = drop 1})

toSeverity :: MySeverity -> Severity
toSeverity = \case
  SDebug -> Debug
  SInfo -> Info
  SWarning -> Warning
  SError -> Error

type AppConfigImpl =
  ( ?_RUN_N :: Int
  , ?_PROCESSED_LOGGER_DELAY :: Int
  , ?_RETRY_DELAY :: Int
  , ?_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT :: Int
  , ?_VSCODE_MARKETPLACE_PAGE_SIZE :: Int
  , ?_VSCODE_MARKETPLACE_PAGE_COUNT :: Int
  , ?_N_RETRY :: Int
  , ?_MAX_MISSING_TIMES :: Int
  , ?_LOG_SEVERITY :: Severity
  )

_MICROSECONDS :: Int
_MICROSECONDS = 1_000_000

main :: IO ()
main = do
  -- we'll let logs be written to stdout as soon as they come
  hSetBuffering stdout NoBuffering
  config <- getEnv _CONFIG_ENV_VAR `catchAny` (\x -> error [i|No config file specified in the #{_CONFIG_ENV_VAR} environment variable\n\n#{x}|])
  appConfig <- eitherDecodeFileStrict' config
  case appConfig of
    Left err -> error [i|Could not decode the config file\n\n#{err}|]
    Right AppConfig{..} ->
      let
        ?_RUN_N = runN ^. non 1
        ?_PROCESSED_LOGGER_DELAY = (processedLoggerDelay ^. non 2) * _MICROSECONDS
        ?_RETRY_DELAY = (retryDelay ^. non 2) * _MICROSECONDS
        ?_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT = (openVsxRequestResponseTimeout ^. non 100) * _MICROSECONDS
        ?_VSCODE_MARKETPLACE_PAGE_SIZE = vscodeMarketplacePageSize ^. non 1_000
        ?_VSCODE_MARKETPLACE_PAGE_COUNT = vscodeMarketplacePageCount ^. non 70
        ?_N_RETRY = nRetry ^. non 3
        ?_LOG_SEVERITY = toSeverity (logSeverity ^. non SInfo)
        ?_MAX_MISSING_TIMES = maxMissingTimes ^. non 5
       in
        withBackgroundLogger @IO defCapacity (cfilter (\(Msg sev _ _) -> sev >= ?_LOG_SEVERITY) $ formatWith fmtMessage logTextStdout) (pure ()) $ \logger -> do
          usingLoggerT logger $ logInfo [i|#{START} Updating extensions|]
          -- we'll run the extension crawler and a fetcher a given number of times on both target sites
          traverse_
            ( \target ->
                replicateM_ ?_RUN_N $
                  processTarget
                    ProcessTargetEnv
                      { dataDir = dataDir ^. non "data"
                      , nThreads = (targetSelect target nThreadsVSCodeMarketplace nThreadsOpenVSX) ^. non 100
                      , queueCapacity = queueCapacity ^. non 200
                      , ..
                      }
            )
            [ VSCodeMarketplace
            , OpenVSX
            ]
          usingLoggerT logger $ logInfo [i|#{FINISH} Updating extensions|]
