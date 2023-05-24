{- FOURMOLU_DISABLE -}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}
{-# HLINT ignore "Redundant bracket" #-}
{-# HLINT ignore "Use lambda-case" #-}
{-# HLINT ignore "Use bimap" #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# HLINT ignore "Redundant lambda" #-}
{-# LANGUAGE TupleSections #-}
{- FOURMOLU_ENABLE -}

module Main (main) where

import Colog (LoggerT, Message, Msg (..), WithLog, cfilter, fmtMessage, formatWith, logDebug, logError, logInfo, logTextStdout, usingLoggerT)
import Colog.Concurrent (defCapacity, withBackgroundLogger)
import Configs
import Control.Concurrent (threadDelay)
import Control.Concurrent.Async (forConcurrently, mapConcurrently_)
import Control.Concurrent.Async.Pool (mapConcurrently, withTaskGroup)
import Control.Concurrent.STM (STM, TMVar, TVar, atomically, newTMVarIO, newTVarIO, putTMVar, readTVar, readTVarIO, takeTMVar, tryReadTMVar, writeTVar)
import Control.Concurrent.STM.TBMQueue (TBMQueue, closeTBMQueue, newTBMQueueIO, peekTBMQueue, tryReadTBMQueue, writeTBMQueue)
import Control.Exception (throw)
import Control.Lens (Bifunctor (bimap), Field1 (_1), Traversal', filtered, has, non, only, to, traversed, (%~), (+~), (<&>), (^.), (^..), (^?), _Just)
import Control.Monad (guard, replicateM_, unless, void, when)
import Control.Monad.IO.Class (MonadIO (..))
import Data.Aeson (ToJSON, Value (..), eitherDecodeFileStrict', encode, withObject, (.:), (.:?))
import Data.Aeson.Lens (key, nth, _Array, _String)
import Data.Aeson.Types (parseMaybe)
import Data.ByteString qualified as BS
import Data.Either (fromRight)
import Data.Foldable (Foldable (foldl'), traverse_)
import Data.Function (fix, (&))
import Data.Generics.Labels ()
import Data.HashMap.Strict qualified as Map
import Data.HashSet qualified as Set
import Data.List (partition)
import Data.List qualified as DL
import Data.Maybe (fromJust, isJust, isNothing)
import Data.String (IsString (fromString))
import Data.String.Interpolate (i)
import Data.Text (Text, pack, strip)
import Data.Text qualified as Text
import Data.Text.Lazy qualified as T
import Extensions
import GHC.Generics (Generic)
import GHC.IO.Handle (BufferMode (NoBuffering), Handle, hSetBuffering)
import GHC.IO.IOMode (IOMode (AppendMode, WriteMode))
import Network.HTTP.Client (Response (..))
import Network.HTTP.Client.Conduit (Request (method))
import Network.HTTP.Simple (JSONException, httpJSONEither, setRequestBodyJSON, setRequestHeaders)
import System.Environment (getEnv)
import System.IO (stdout, withFile)
import Text.Pretty.Simple (defaultOutputOptionsNoColor, pShowOpt)
import Turtle (Alternative (empty), mktree, rm, shellStrictWithErr, testfile)
import UnliftIO.Exception (catchAny, finally)

-- | Select a base API URL depending on the target
apiUrl :: Target -> String
apiUrl target =
  targetSelect
    target
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
    "https://open-vsx.org/vscode/gallery/extensionquery"

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
processedLogger :: AppConfig' => Int -> TMVar Int -> LoggerT Message IO ()
processedLogger total processed = flip fix 0 $ \ret n -> do
  p <- liftIO $ atomically $ tryReadTMVar processed
  traverse_
    ( \cnt -> do
        when (cnt /= n) $ logInfo [i|#{INFO} Processed (#{cnt}/#{total}) extensions|]
        liftIO $ threadDelay ?config.processedLoggerDelay
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

-- | Get an extension from a target site and pass info about it to other threads
--
-- We do this by using the thread-safe data structures like special queues and vars
getExtension :: AppConfig' => Target -> TBMQueue ExtensionInfo -> TBMQueue ExtensionConfig -> TMVar Int -> TVar Int -> ExtensionConfig -> LoggerT Message IO ()
getExtension target extInfoQueue extFailedConfigQueue extProcessedN extFailedN extConfig@ExtensionConfig{platform, lastUpdated, missingTimes, engineVersion, version} = do
  let
    -- select an action for a target
    publisher = extConfig.publisher & #_publisher %~ Text.toLower
    name = extConfig.name & #_name %~ Text.toLower
    select :: a -> a -> a
    select = targetSelect target
    extName = [i|#{publisher}.#{name}|] :: Text
  logDebug [i|#{START} Requesting info about #{extName} from #{ppTarget target}|]
  isFailed <- do
    let
      -- version = fromJust extVersion
      -- and can prepare a url for a target site
      platformInfix :: Text =
        ( case platform of
            PUniversal -> ""
            x -> [i|/#{x}|]
        )
      platformSuff :: Text =
        ( case platform of
            PUniversal -> ""
            x -> select [i|targetPlatform=#{x}|] [i|@#{x}|]
        )
      url :: Text
      url =
        select
          [i|https://#{publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/#{publisher}/extension/#{name}/#{version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?#{platformSuff}|]
          [i|https://open-vsx.org/api/#{publisher}/#{name}#{platformInfix}/#{version}/file/#{extName}-#{version}#{platformSuff}.vsix|]

    logDebug [i|#{START} Fetching #{extName} from #{url}|]
    -- and let nix fetch a file from that url into nix/store
    -- nix produces a SHA (we extract it via `jq`)
    let timeout' = ?config.requestResponseTimeout
    (_, strip -> sha256, errText) <- shellStrictWithErr [i|nix store prefetch-file --timeout #{timeout'} --json #{url} --name #{extName}-#{version}-#{platform} | jq -r .hash|] empty
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
  when
    isFailed
    do
      liftIO $ atomically $ writeTBMQueue extFailedConfigQueue extConfig
      liftIO $ atomically $ readTVar extFailedN >>= \x -> writeTVar extFailedN (x + 1)
  -- when finished, we update a shared counter
  liftIO $ atomically $ takeTMVar extProcessedN >>= \x -> putTMVar extProcessedN (x + 1)

-- | Fetch the extensions given their configurations
runFetcher :: AppConfig' => FetcherConfig IO -> IO ()
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

  let mkKey :: Publisher -> Name -> Platform -> Version -> LastUpdated -> (Publisher, Name, Platform, Version, LastUpdated)
      mkKey publisher name platform version lastUpdated = (publisher, name, platform, version, lastUpdated)
      mkKeyInfo ExtensionInfo{..} = mkKey publisher name platform version lastUpdated
      mkKeyConfig ExtensionConfig{..} = mkKey publisher name platform version lastUpdated
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
          ^.. _1 . traversed . filtered (\c -> c.missingTimes + 1 < ?config.maxMissingTimes)
          & traversed . #missingTimes +~ 1
      -- these missing info are turned into configs so that they can be fetched again
      -- this conversion preserves the missing times counter
      extensionInfoMissingConfigs = extensionInfoMissing <&> (\ExtensionInfo{..} -> ExtensionConfig{..})
      -- combine new and old missing configs
      extensionConfigsMissing' = extensionConfigsMissing <> extensionInfoMissingConfigs
      -- and calculate the number of the configs of extensions that are missing
      numberExtensionConfigsMissing = length extensionConfigsMissing'
  -- collect extensions from cache that are not present
  logInfo_ [i|#{START} Running a fetcher on #{ppTarget target}|]
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
      logInfo_ [i|#{FINISH} Running a fetcher on #{ppTarget target}|]

-- | Retry an action a given number of times with a given delay and log about its status
retry_ :: (MonadIO m, WithLog env Message m, AppConfig') => (Int -> m b) -> Int -> Text -> Text -> m b
retry_ ret n msg msgTryExtra =
  if n > 0
    then logDebug [i|#{FAIL} Attempt #{n}. #{msg}. #{msgTryExtra}|] >> liftIO (threadDelay ?config.retryDelay) >> ret (n - 1)
    else logDebug [i|#{ABORT} All #{n} attempts have failed|] >> error [i|#{msg}|]

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
        let flags z = filter (not . Text.null) (Text.splitOn ", " z)
         in maybe
              False
              -- check if all flags are allowed
              (\z -> length (flags z) == length (flags z & DL.intersect extFlagsAllowed))
              (y ^? key "flags" . _String)
    )

mkRequest :: ToJSON a => Target -> a -> Request
mkRequest target request_ =
  setRequestBodyJSON request_
    $ setRequestHeaders
      [ ("CONTENT-TYPE", "application/json")
      , ("ACCEPT", "application/json; api-version=6.1-preview.1")
      , ("ACCEPT-ENCODING", "gzip")
      ]
    $ (fromString (apiUrl target)){method = "POST"}

mkEitherRequest :: (MonadIO w, ToJSON a) => Target -> a -> w (Response (Either JSONException Value))
mkEitherRequest target request_ = httpJSONEither @_ @Value (mkRequest target request_)

-- | Get a list of extension configs from VSCode Marketplace
getConfigs :: AppConfig' => Target -> LoggerT Message IO [ExtensionConfig]
getConfigs target =
  let nRetry = ?config.nRetry
      siteConfig = targetSelect target ?config.vscodeMarketplace ?config.openVSX
   in flip fix nRetry $ \ret (nRetry_ :: Int) -> do
        let
          pageCount = siteConfig.pageCount
          pageSize = siteConfig.pageSize
          requestExtensionsList pageNumber =
            Req
              { filters =
                  [ Filter
                      { criteria =
                          [ Criterion{filterType = 8, value = "Microsoft.VisualStudio.Code"}
                          , Criterion{filterType = 12, value = "4096"}
                          ]
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
        pages <- traverse responseBody <$> liftIO (forConcurrently [1 .. pageCount] (mkEitherRequest target . requestExtensionsList))
        case pages of
          -- if we were unsuccessful, we need to retry
          Left l -> retry_ ret (nRetry - nRetry_ + 1) [i|Getting info about extensions from #{ppTarget target}|] [i|#{l}|]
          Right r -> do
            pure $
              r
                ^.. traversed
                  . key "results"
                  . nth 0
                  . key "extensions"
                  . _Array
                  . traversed
                  . filteredByFlags
                  . to
                    ( parseMaybe
                        ( withObject [i|Extension|] $ \o -> do
                            name :: Name <- o .: "extensionName"
                            publisher :: Publisher <- o .: "publisher" >>= \x -> x .: "publisherName"
                            versions_ :: [Value] <- o .: "versions"
                            pure $
                              versions_
                                ^.. traversed
                                  . to
                                    ( parseMaybe
                                        ( withObject [i|Version|] $ \o1 -> do
                                            lastUpdated <- o1 .: "lastUpdated"
                                            version <- o1 .: "version"
                                            platform <- o1 .:? "targetPlatform" <&> (^. non PUniversal)
                                            properties :: [Value] <- o1 .: "properties"
                                            let engineVersion =
                                                  properties
                                                    ^? traversed
                                                    . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.Engine"))
                                                    . key "value"
                                                    . _String
                                                    . _EngineVersion
                                                missingTimes = 0
                                            guard (isJust engineVersion)
                                            pure ExtensionConfig{engineVersion = fromJust engineVersion, ..}
                                        )
                                    )
                                  . _Just
                        )
                    )
                  . _Just
                  . traversed

-- | Get a list of extension configs from VSCode Marketplace
getConfigsRelease :: AppConfig' => Target -> LoggerT Message IO [ExtensionConfig]
getConfigsRelease target = do
  logInfo [i|#{START} Collecting release versions of extensions|]
  let nRetry = ?config.nRetry
      siteConfig = targetSelect target ?config.vscodeMarketplace ?config.openVSX
   in flip fix nRetry $ \ret (nRetry_ :: Int) -> do
        let
          extensionCriteria =
            siteConfig.release._releaseExtensions
              ^.. traversed . to (\ReleaseExtension{..} -> Criterion{filterType = 7, value = [i|#{_publisher}.#{_name}|]})
          pageSize = length extensionCriteria
          requestExtensionsList =
            Req
              { filters =
                  [ Filter
                      { criteria = [Criterion{filterType = 8, value = "Microsoft.VisualStudio.Code"}] <> extensionCriteria
                      , sortBy = 0
                      , sortOrder = 0
                      , pageNumber = 1
                      , ..
                      }
                  ]
              , assetTypes = []
              , flags = 1073
              }
        logInfo [i|#{START} Collecting release extension pages.|]
        pages <- responseBody <$> liftIO (mkEitherRequest target requestExtensionsList)
        case pages of
          -- if we were unsuccessful, we need to retry
          Left l -> retry_ ret (nRetry - nRetry_ + 1) [i|Getting info about extensions from #{ppTarget target}|] [i|#{l}|]
          Right r -> do
            -- liftIO $ encodeFile "tmp/release.json" r
            pure $
              r
                ^.. key "results"
                  . nth 0
                  . key "extensions"
                  . _Array
                  . traversed
                  . filteredByFlags
                  . to
                    ( parseMaybe
                        ( withObject [i|Extension|] $ \o -> do
                            name :: Name <- o .: "extensionName"
                            publisher :: Publisher <- o .: "publisher" >>= \x -> x .: "publisherName"
                            versions_ :: [Value] <- o .: "versions"
                            let configs =
                                  versions_
                                    ^.. traversed
                                      . to
                                        ( parseMaybe
                                            ( withObject [i|Version|] $ \o1 -> do
                                                lastUpdated <- o1 .: "lastUpdated"
                                                version <- o1 .: "version"
                                                platform <- o1 .:? "targetPlatform" <&> (^. non PUniversal)
                                                properties :: [Value] <- o1 .: "properties"
                                                let engineVersion =
                                                      properties
                                                        ^? traversed
                                                        . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.Engine"))
                                                        . key "value"
                                                        . _String
                                                        . _EngineVersion
                                                    missingTimes = 0
                                                    preRelease =
                                                      properties
                                                        ^? traversed
                                                        . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.PreRelease"))
                                                guard (isNothing preRelease && isJust engineVersion)
                                                pure ExtensionConfig{engineVersion = fromJust engineVersion, ..}
                                            )
                                        )
                                      . _Just
                                -- we need to possibly get the most recent config for each platform
                                -- thus, we initialize a map `platform -> got a config`
                                platformMap = (Map.fromList ((enumFrom minBound :: [Platform]) <&> (,Nothing)))
                                -- we insert all configs
                                -- if in the map, there's already a config for a platform, we don't insert it
                                configsFiltered = foldl' (\mp conf -> Map.insertWith (\new old -> case old of Nothing -> new; x -> x) conf.platform (Just conf) mp) platformMap configs
                                -- finally, we traverse the map values and filter out the non-existing configs
                                -- btw. it may happen, that there's no config for a platform
                                configsFiltered' = configsFiltered ^.. traversed . _Just
                            pure configsFiltered'
                        )
                    )
                  . _Just
                  . traversed

-- | Run a crawler depending on the target site to (hopefully) get the extension configs
runCrawler :: AppConfig' => CrawlerConfig IO -> IO ([ExtensionConfig], [ExtensionConfig])
runCrawler CrawlerConfig{..} =
  usingLoggerT logger do
    logInfo [i|#{START} Updating info about extensions from #{ppTarget target}.|]
    -- we select the target crawler and run it
    -- on all configs
    configs <- getConfigs target
    -- on release configs
    configsRelease <- getConfigsRelease target
    -- we normalize the configs by lowercasing the extension name and publisher
    let
      normalizeConfig = \config -> config & #name . #_name %~ Text.toLower & #publisher . #_publisher %~ Text.toLower
      configsNormalized = normalizeConfig <$> configs
      configsReleaseNormalized = normalizeConfig <$> configsRelease

    logInfo [i|#{FINISH} Updating info about extensions from #{ppTarget target}.|]
    -- finally, we return the configs
    pure (configsNormalized, configsReleaseNormalized)

pShow' :: Show a => a -> Text
pShow' = T.toStrict . pShowOpt defaultOutputOptionsNoColor

processTarget :: AppConfig' => ProcessTargetConfig IO -> IO ()
processTarget ProcessTargetConfig{..} =
  do
    let
      cacheDir :: FilePath = [i|#{dataDir}/cache|]
      tmpDir :: FilePath = [i|#{dataDir}/tmp|]

      mkTargetJSON :: FilePath -> FilePath
      mkTargetJSON x = [i|#{x}/#{showTarget target}-latest.json|]
      mkTargetReleaseJSON :: FilePath -> FilePath
      mkTargetReleaseJSON x = [i|#{x}/#{showTarget target}-release.json|]
      nRetry = ?config.nRetry

    -- we first run a crawler to get the extension configs
    (configsNormalized, configsReleaseNormalized) <- runCrawler CrawlerConfig{..}

    -- then, we run a fetcher
    runFetcher FetcherConfig{extConfigs = configsReleaseNormalized, mkTargetJSON = mkTargetReleaseJSON, ..}
    runFetcher FetcherConfig{extConfigs = configsNormalized, ..}

    -- in case of errors, rethrow an exception
    `catchAny` \x -> usingLoggerT logger (logError [i|Got an exception when requesting #{ppTarget target}:\n #{x}|]) >> throw x

main :: IO ()
main = do
  -- we'll let logs be written to stdout as soon as they come
  hSetBuffering stdout NoBuffering
  config <- getEnv _CONFIG_ENV_VAR `catchAny` (\x -> error [i|No config file specified in the #{_CONFIG_ENV_VAR} environment variable\n\n#{x}|])
  appConfig <- eitherDecodeFileStrict' config
  case appConfig of
    Left err -> error [i|Could not decode the config file\n\n#{err}|]
    Right conf ->
      let
        config'@AppConfig{..} = mkDefaultAppConfig conf
       in
        let ?config = config'
         in withBackgroundLogger @IO defCapacity (cfilter (\(Msg sev _ _) -> sev >= logSeverity) $ formatWith fmtMessage logTextStdout) (pure ()) $ \logger -> do
              usingLoggerT logger $ logInfo [i|#{START} Updating extensions|]
              -- we'll run the extension crawler and a fetcher a given number of times on both target sites
              traverse_
                ( \target ->
                    replicateM_ ?config.runN $
                      processTarget
                        ProcessTargetConfig
                          { dataDir = dataDir
                          , nThreads = (targetSelect target vscodeMarketplace.nThreads openVSX.nThreads)
                          , queueCapacity = queueCapacity
                          , ..
                          }
                )
                [ VSCodeMarketplace
                , OpenVSX
                ]
              usingLoggerT logger $ logInfo [i|#{FINISH} Updating extensions|]
