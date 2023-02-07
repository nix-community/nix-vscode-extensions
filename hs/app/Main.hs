{-# LANGUAGE BangPatterns #-}
{-# HLINT ignore "Use bimap" #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# HLINT ignore "Redundant bracket" #-}
{-# LANGUAGE InstanceSigs #-}
{-# HLINT ignore "Use lambda-case" #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE NumericUnderscores #-}
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

import Colog (LogAction, LoggerT, Message, Msg (..), Severity (..), WithLog, cfilter, fmtMessage, formatWith, logDebug, logError, logInfo, logTextStdout, usingLoggerT)
import Colog.Concurrent (defCapacity, withBackgroundLogger)
import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (forConcurrently, mapConcurrently_)
import Control.Concurrent.Async.Pool (mapConcurrently, withTaskGroup)
import Control.Concurrent.STM (STM, TMVar, atomically, newTMVarIO, readTMVar, takeTMVar, tryReadTMVar, putTMVar)
import Control.Concurrent.STM.TBMQueue (TBMQueue, closeTBMQueue, newTBMQueueIO, peekTBMQueue, tryReadTBMQueue, writeTBMQueue)
import Control.Lens (filtered, traversed, (^..), (^?))
import Control.Monad (replicateM_, unless, void, when)
import Control.Monad.Catch (MonadCatch (catch), SomeException (..), finally, try)
import Control.Monad.IO.Class (MonadIO (..))
import Data.Aeson (FromJSON (..), ToJSON, Value (..), eitherDecodeFileStrict', encode, withObject, (.:))
import Data.Aeson.Lens (key, nth, _Array, _Integer, _String)
import Data.Aeson.Types (parseMaybe)
import Data.ByteString qualified as BS
import Data.Either (fromRight, isLeft)
import Data.Foldable (traverse_)
import Data.Function (fix, (&))
import Data.HashMap.Strict qualified as Map
import Data.HashSet qualified as Set
import Data.Hashable (Hashable)
import Data.List (partition)
import Data.List qualified as DL
import Data.Maybe (fromJust, isJust, isNothing, mapMaybe)
import Data.String (IsString (fromString))
import Data.String.Interpolate (i)
import Data.Text (Text, strip)
import Data.Text qualified as Text
import Data.Time (UTCTime)
import GHC.Generics (Generic)
import GHC.IO.Handle (BufferMode (NoBuffering), Handle, hSetBuffering)
import GHC.IO.IOMode (IOMode (AppendMode, WriteMode))
import Network.HTTP.Client (Response (..), responseTimeoutMicro)
import Network.HTTP.Client.Conduit (Request (method))
import Network.HTTP.Simple (httpJSONEither, setRequestBodyJSON, setRequestHeaders, setRequestResponseTimeout)
import Network.HTTP.Types (status200)
import System.IO (stdout, withFile)
import Turtle (Alternative (empty), mktree, rm, shellStrictWithErr, testfile)

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

-- | Possible targets
data Target = VSCodeMarketplace | OpenVSX deriving (Eq)

-- | A simple config that is enough to fetch an extension
data ExtensionConfig = ExtensionConfig
  { name :: Text
  , publisher :: Text
  , lastUpdated :: UTCTime
  }
  deriving (Generic, FromJSON, ToJSON, Show, Eq, Hashable)

-- | Full necessary info about an extension
data ExtensionInfo = ExtensionInfo
  { name :: Text
  , publisher :: Text
  , lastUpdated :: UTCTime
  , version :: Text
  , url :: Text
  , sha256 :: Text
  }
  deriving (Generic, FromJSON, ToJSON, Show)

-- | Select a base API URL based on the target
apiUrl :: Target -> String
apiUrl target =
  targetSelect
    target
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    "https://open-vsx.org/api"

-- | select an action based on a target
targetSelect :: Target -> p -> p -> p
targetSelect target f g =
  case target of
    VSCodeMarketplace -> f
    OpenVSX -> g

-- | convert a target to a string
showTarget :: Target -> String
showTarget target = targetSelect target "vscode-marketplace" "open-vsx"

-- | read everything from a queue into a list
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
              maybe
                (pure ())
                ( \case
                    -- handle the case when it's the first write
                    -- but the queue is empty
                    [] -> ret True
                    -- handle another case
                    xs -> encodeFirstList h xs
                )
                extData
            else -- next time, we can write all values from the list in the same way
              maybe (pure ()) (traverse_ (\x -> BS.hPutStr h [i|, #{encode x}\n|])) extData
          -- this type of queue may become `closed`
          -- in this case, values that we read from it will be `Nothing`
          -- unless such a situation happens, we need to repeat our loop
          unless (isNothing extData) (ret False)
      -- even if this logger thread is killed by an exception,
      -- we want the opened file to store a valid JSON.
      -- so, we append a closing bracket
      `finally` BS.hPutStr h "]"

processedLogger :: Int -> TMVar Int -> LoggerT Message IO ()
processedLogger total processed = flip fix 0 $ \ret n -> do
  p <- liftIO $ atomically $ tryReadTMVar processed
  maybe
    (pure ())
    ( \cnt -> do
        when (cnt /= n) $ logInfo [i|#{INFO} Processed (#{cnt}/#{total}) extensions|]
        liftIO $ threadDelay _PROCESSED_LOGGER_DELAY
        ret cnt
    )
    p

-- | Get an extension from a target site and pass info about it to other threads
getExtension :: Target -> TBMQueue ExtensionInfo -> TBMQueue ExtensionConfig -> TMVar Int -> ExtensionConfig -> LoggerT Message IO ()
getExtension target extInfoQueue extFailedConfigQueue extProcessedN c@ExtensionConfig{..} = do
  let
    select = targetSelect target
    extName = [i|#{publisher}.#{name}|] :: Text
    -- a template of a request about an extension to VSCode Marketplace
    requestExtension :: Text -> Req
    requestExtension name_ =
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
    -- prepare a request based on the target site
    request =
      select
        ( setRequestBodyJSON (requestExtension extName) $
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
    Left err -> logDebug [i|#{FAIL} Requesting info about #{extName} from #{ppTarget target}. The error:\n #{err}|]
    Right response -> do
      isFailed <-
        if responseStatus response /= status200 || isLeft (responseBody response)
          then do
            logDebug [i|#{FAIL} Requesting info about #{extName} from #{ppTarget target}. Server response:\n #{response}|]
            pure True
          else do
            -- if we successfully get the response body, it should contain a JSON value
            let body :: Value = fromRight undefined (responseBody response)
                -- based on the target site, we use an appropriate way to extract a version from that JSON value
                extVersion =
                  select
                    (body ^? key "results" . nth 0 . key "extensions" . nth 0 . key "versions" . nth 0 . key "version" . _String)
                    (body ^? key "version" . _String)
            if isNothing extVersion
              then do
                logDebug $
                  [i|#{FAIL} Getting the version of #{extName}.|]
                    <> ( if target == VSCodeMarketplace && (null (body ^.. key "results" . nth 0 . key "extensions" . _Array . traversed))
                          then -- on VSCode marketplace, if there's no info about an extension,
                          -- the `results.extensions` value of a body will be an empty array
                            [i| #{ppTarget target} doesn't provide info about this extension.|]
                          else mempty
                       )
                pure True
              else do
                let version = fromJust extVersion
                    -- we prepare a url for a target site
                    url =
                      select
                        [i|https://#{publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/#{publisher}/extension/#{name}/#{version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage|]
                        [i|https://open-vsx.org/api/#{publisher}/#{name}/#{version}/file/#{extName}-#{version}.vsix|]
                logDebug [i|#{START} Fetching #{extName} from #{url}|]
                -- and let nix fetch a file from that url into nix/store
                -- nix produces a SHA (we extract it via `jq`)
                (_, strip -> sha256, errText) <- shellStrictWithErr [i|nix store prefetch-file --json #{url} | jq -r .hash|] empty
                if not (Text.null errText)
                  then do
                    logDebug [i|#{FAIL} Fetching #{extName} from #{url}. The stderr:\n#{errText}|]
                    pure True
                  else do
                    logInfo [i|#{FINISH} Fetching extension #{extName} from #{url}.|]
                    -- when everything is ok, we write the info into a queue with extension info
                    -- this is to let other threads read from it
                    liftIO $ atomically $ writeTBMQueue extInfoQueue $ ExtensionInfo{..}
                    pure False
      -- if at some point we failed to obtain an extension's info,
      -- we write its config into a queue for failed configs (just in case)
      when isFailed $ liftIO $ atomically $ writeTBMQueue extFailedConfigQueue c
  -- when finished, we update a shared counter
  -- to let other threads know that another extension was processed
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
runFetcher :: FetcherConfig IO -> IO ()
runFetcher FetcherConfig{..} = do
  let fetchedTmpDir :: FilePath = [i|#{tmpDir}/fetched|]
      failedTmpDir :: FilePath = [i|#{tmpDir}/failed|]
  -- if don't exist, we create the directories for files with fetched, failed, and cached extensions
  traverse_ (\x -> mktree [i|#{x}|]) [fetchedTmpDir, failedTmpDir, cacheDir]
  -- if there were previous files with given names, we remove them
  traverse_ (\x -> let f = [i|#{mkTargetJSON x}|] in testfile f >>= (`when` rm f)) [fetchedTmpDir, failedTmpDir]

  -- if there was a file with cached info, we read it into a list
  infoCache <-
    fromRight []
      <$> ( eitherDecodeFileStrict' (mkTargetJSON cacheDir)
              `catch` (\(_ :: SomeException) -> pure (Left ("Error reading file" :: String)))
          )

  let mkKey :: Text -> Text -> UTCTime -> Text
      mkKey publisher name lastUpdated = [i|#{publisher}-#{name}-#{lastUpdated}|]
      -- we load the cached info into a map for quicker access
      infoCacheMap :: Map.HashMap Text ExtensionInfo
      infoCacheMap = Map.fromList ((\d@ExtensionInfo{..} -> (mkKey publisher name lastUpdated, d)) <$> infoCache)
      -- also, we filter out the duplicates among the extension configs
      configs = Set.toList . Set.fromList $ extConfigs
  -- we partition the extension configs based on if they're present in the cache
  let (present, missing) =
        partition
          (isJust . fst)
          ((\c@ExtensionConfig{..} -> (Map.lookup (mkKey publisher name lastUpdated) infoCacheMap, c)) <$> configs)
      presentData = fromJust . fst <$> present
      missingConfigs = snd <$> missing
      -- and calculate the number of the configs of extensions that are missing
      extMissingN = length missingConfigs
  usingLoggerT logger do
    logInfo [i|#{INFO} From #{ppTarget target} have #{length presentData} cached extensions|]
    logInfo [i|#{START} Updating cached info about #{length missingConfigs} extension(s) from #{ppTarget target}|]
  -- we prepare the shared queues and variables
  extInfoQueue <- newTBMQueueIO queueCapacity
  extFailedConfigQueue <- newTBMQueueIO queueCapacity
  extProcessed <- newTMVarIO 0
  -- as well as file names where threads will write to
  let extInfoFile = mkTargetJSON fetchedTmpDir
      extFailedConfigFile = mkTargetJSON failedTmpDir
  -- and run together
  ( mapConcurrently_
      id
      [ -- a logger reads from a queue and logs info about the number of successfully processed extensions
        (usingLoggerT logger $ processedLogger extMissingN extProcessed)
      , -- a logger that writes the info about successfully fetched extensions' info into a file
        (extLogger extInfoFile extInfoQueue)
      , -- a logger that writes the info about failed extensions' info into a file
        (extLogger extFailedConfigFile extFailedConfigQueue)
      , -- and an action that spawns a limited group of threads to fetch the extensions
        -- it's more efficient than spawning a thread per each element of the list with extensions' configs
        ( withTaskGroup nThreads $ \g -> do
            void
              ( mapConcurrently
                  g
                  (usingLoggerT logger . (getExtension target extInfoQueue extFailedConfigQueue extProcessed))
                  missingConfigs
              )
            -- when all configs are processed, we need to close both queues
            -- this will let loggers know that they should quit
            atomically $ closeTBMQueue extInfoQueue
            atomically $ closeTBMQueue extFailedConfigQueue
            -- make this var empty to notify the threads reading from it
            atomically $ void $ takeTMVar extProcessed
        )
      ]
    )
    -- even if there are some errors
    -- we want to append the info about the newly fetched extensions to the cache
    -- that's why, we run this action in a `finally` block
    `finally` do
      usingLoggerT logger $ logInfo [i|#{START} Caching updated info about extensions from #{ppTarget target}|]
      -- we combine the cached info with the new info that we read from a file
      -- and sort the list
      extSorted <-
        DL.sortBy (\x y -> compare (mkKey x.publisher x.name x.lastUpdated) (mkKey y.publisher y.name y.lastUpdated))
          . (++ presentData)
          . fromRight []
          <$> (eitherDecodeFileStrict' extInfoFile `catch` (\(_ :: SomeException) -> pure $ Left "Error reading a file"))
      -- after that, we compactly write the extensions' info into the cache file
      withFile (mkTargetJSON cacheDir) WriteMode $ \h -> do
        BS.hPutStr h "[ "
        case extSorted of
          [] -> pure ()
          xs -> encodeFirstList h xs
        BS.hPutStr h "]"
      usingLoggerT logger $ logInfo [i|#{FINISH} Caching updated info about extensions from #{ppTarget target}|]

-- | handle the case when we need to write the first list of extensions' info into a file
encodeFirstList :: ToJSON a => Handle -> [a] -> IO ()
encodeFirstList h (x : xs) = BS.hPutStr h ([i|#{encode x}\n|]) >> traverse_ (\y -> BS.hPutStr h ([i|, #{encode y}\n|])) xs
encodeFirstList _ _ = error "Please, check the pattern matching at where you call this function"

-- | Retry an action a given number of times with a given delay and log about its status
retry_ :: (MonadIO m, WithLog env Message m, Monoid b) => (Int -> m b) -> Int -> Text -> Text -> m b
retry_ ret n msg msgTryExtra =
  if n > 0
    then logDebug [i|#{FAIL} Attempt #{n}. #{msg}. #{msgTryExtra}|] >> liftIO (threadDelay _RETRY_DELAY) >> ret (n - 1)
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

extFlags :: [Text]
extFlags = ["validated", "public", "preview", "verified"]

-- | Get a list of extension configs from VSCode Marketplace
getConfigsVSCodeMarketplace :: Int -> LoggerT Message IO (Maybe [ExtensionConfig])
getConfigsVSCodeMarketplace nRetry = flip fix nRetry $ \ret (nRetry_ :: Int) -> do
  let
    pageCount = _VSCODE_MARKETPLACE_PAGE_COUNT
    pageSize = _VSCODE_MARKETPLACE_PAGE_SIZE
    target = VSCodeMarketplace
    requestExtensionsList :: Int -> Req
    requestExtensionsList pageNumber =
      Req
        { filters =
            [ Filter
                { criteria = [Criterion{filterType = 8, value = "Microsoft.VisualStudio.Code"}]
                , sortBy = 4
                , sortOrder = 2
                , ..
                }
            ]
        , assetTypes = []
        , flags = 0
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
      -- we'll turn each page into a list of extension configs, concatenate them and return
      pure . pure $
        foldMap
          ( \p ->
              -- first, we need to filter out the values, corresponding to extensions with inappropriate flags
              ( p
                  ^.. (key "results" . nth 0 . key "extensions" . _Array . traversed)
                    . filtered
                      ( \y ->
                          maybe
                            False
                            (\z -> not $ null ((Text.splitOn ", " z) & DL.intersect extFlags))
                            (y ^? key "flags" . _String)
                      )
              )
                -- next, we parse each value and extract the necessary info from it
                & ( mapMaybe
                      ( parseMaybe
                          ( ( withObject [i|#{ppTarget target} Extension|] $ \o -> do
                                name <- o .: "extensionName"
                                publisher <- o .: "publisher" >>= \x -> x .: "publisherName"
                                lastUpdated <- o .: "lastUpdated"
                                pure $ ExtensionConfig{..}
                            )
                          )
                      )
                  )
          )
          r

-- | Get a list of extension configs from Open VSX
getConfigsOpenVSX :: Int -> LoggerT Message IO (Maybe [ExtensionConfig])
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
          let count = fromJust extCount
          logInfo [i|#{FINISH} Getting the extension count from #{ppTarget_}. There are #{count} extensions (including the platform-dependent ones).|]
          let
            req =
              setRequestResponseTimeout (responseTimeoutMicro _OPEN_VSX_REQUEST_RESPONSE_TIMEOUT)
                $ setRequestHeaders
                  [ ("CONTENT-TYPE", "application/json")
                  , ("ACCEPT", "application/json; api-version=6.1-preview.1")
                  , ("ACCEPT-ENCODING", "gzip")
                  ]
                $ [i|#{baseURL}/-/search?includeAllVersions=false&size=#{count}|]{method = "GET"}
          logInfo [i|#{START} Getting the extensions from #{ppTarget target}|]
          extListResp <- liftIO $ try (httpJSONEither @_ @Value req)
          case extListResp of
            -- if there are any exceptions, we'll retry
            Left (err :: SomeException) -> retry_ retryList (nRetry - nRetryList + 1) [i|Requesting the extensions list from #{ppTarget target}|] [i|#{err}|]
            Right extListResp_ ->
              if responseStatus extListResp_ /= status200 || isLeft (responseBody extListResp_)
                then retry_ retryList (nRetry - nRetryList + 1) [i|Getting extension list from #{ppTarget_}|] [i|Got: #{responseBody extListResp_}|]
                else do
                  -- if everything was ok, we extract the list of the values that correspond to extensions
                  -- from the response
                  let extList = (fromRight undefined (responseBody extListResp_))
                  pure . pure $
                    -- we filter out the non-universal value

                    -- we filter out the non-universal value
                    ( extList
                        ^.. key "extensions"
                          . _Array
                          . traversed
                          -- non-universal extensions have a download link like "https://open-vsx.org/api/astro-build/astro-vscode/win32-x64/0.29.5/file/astro-build.astro-vscode-0.29.5@win32-x64.vsix"
                          -- this link contains an '@'
                          . filtered (\x -> maybe False (\y -> not ('@' `Text.elem` y)) (x ^? key "files" . key "download" . _String))
                    )
                      -- then, we parse the values to obtain the extension configs
                      & mapMaybe
                        ( parseMaybe
                            ( ( withObject [i|#{ppTarget_} Extension|] $ \o -> do
                                  name <- o .: "name"
                                  publisher <- o .: "namespace"
                                  lastUpdated <- o .: "timestamp"
                                  pure $ ExtensionConfig{..}
                              )
                            )
                        )

-- | Config for a crawler
data CrawlerConfig a = CrawlerConfig
  { target :: Target
  , nRetry :: Int
  , logger :: LogAction a Message
  }

-- | Run a crawler depending on the target site to (hopefully) get the extension configs
runCrawler :: CrawlerConfig IO -> IO (Maybe [ExtensionConfig])
runCrawler CrawlerConfig{..} =
  usingLoggerT logger do
    logInfo [i|#{START} Updating info about extensions from #{ppTarget target}.|]
    -- we select the target crawler and run it
    s <- targetSelect target getConfigsVSCodeMarketplace getConfigsOpenVSX nRetry
    logInfo [i|#{FINISH} Updating info about extensions from #{ppTarget target}.|]
    -- finally, we return what we got
    pure s

main' :: LogAction IO Message -> FilePath -> Int -> Int -> Target -> IO ()
main' logger dataDir nThreads queueCapacity target =
  do
    let
      cacheDir :: FilePath = [i|#{dataDir}/cache|]
      tmpDir :: FilePath = [i|#{dataDir}/tmp|]

      targetJSON :: FilePath = [i|#{showTarget target}.json|]
      mkTargetJSON :: FilePath -> FilePath
      mkTargetJSON x = [i|#{x}/#{targetJSON}|]

      nRetry = _N_RETRY

    -- we first run a crawler, then a fetcher
    -- a crawler will get the extension configs
    -- and the fetcher will fetch them via nix and cache info about them
    runCrawler CrawlerConfig{..} >>= \x -> maybe (pure ()) (\extConfigs -> runFetcher FetcherConfig{..}) x
    `catch` (\(x :: SomeException) -> do usingLoggerT logger $ logError [i|Got an exception when requesting #{ppTarget target}:\n #{x}|])

-- Here are some constants that were used throughout the script

-- | How many times to retry an action
_N_RETRY :: Int
_N_RETRY = 3

-- | How many extension pages to request from VSCode Marketplace
_VSCODE_MARKETPLACE_PAGE_COUNT :: Int
_VSCODE_MARKETPLACE_PAGE_COUNT = 70

-- | How many extensions per a page to request from VSCode Marketplace
_VSCODE_MARKETPLACE_PAGE_SIZE :: Int
_VSCODE_MARKETPLACE_PAGE_SIZE = 1_000

-- | How much time to wait until Open VSX returns a response
_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT :: Int
_OPEN_VSX_REQUEST_RESPONSE_TIMEOUT = 120_000_000

-- | How long to wait before retrying
_RETRY_DELAY :: Int
_RETRY_DELAY = 10_000_000

-- | How much for a logger to wait until logging again
_PROCESSED_LOGGER_DELAY :: Int
_PROCESSED_LOGGER_DELAY = 2_000_000

main :: IO ()
main = do
  -- we'll let logs be written to stdout as soon as they come
  hSetBuffering stdout NoBuffering
  withBackgroundLogger @IO defCapacity (cfilter (\(Msg sev _ _) -> sev > Debug) $ formatWith fmtMessage logTextStdout) (pure ()) $ \logger -> do
    usingLoggerT logger $ logInfo [i|#{START} Updating extensions|]
    -- we'll run the extension crawler and a fetcher several times on both sites
    traverse_ (replicateM_ 2 . main' logger "data" 100 200) [VSCodeMarketplace, OpenVSX]
    usingLoggerT logger $ logInfo [i|#{FINISH} Updating extensions|]
