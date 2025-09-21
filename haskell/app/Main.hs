{-# HLINT ignore "Redundant bracket" #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}

module Main (main) where

import Colog (LogAction (..), Message, Msg (..), WithLog, cfilter, fmtMessage, formatWith, logDebug, logError, logInfo, logTextStdout, usingLoggerT)
import Colog.Concurrent (defCapacity, withBackgroundLogger)
import Configs
import Control.Concurrent (threadDelay)
import Control.Concurrent.Async.Pool (mapConcurrently, withTaskGroup)
import Control.Concurrent.STM.TBMQueue (TBMQueue, closeTBMQueue, newTBMQueueIO, peekTBMQueue, tryReadTBMQueue, writeTBMQueue)
import Control.Exception (throw)
import Control.Lens (Bifunctor (bimap), Field1 (_1), Traversal', filtered, has, non, only, to, traversed, (+~), (.~), (<&>), (^.), (^..), (^?), _Just)
import Control.Monad (forM_, guard, unless, void, when)
import Control.Monad.IO.Class (MonadIO (..))
import Data.Aeson (ToJSON, Value (..), eitherDecodeFileStrict', encode, withObject, (.:), (.:?))
import Data.Aeson.Lens (key, nth, _Array, _String)
import Data.Aeson.Types (parseMaybe)
import Data.ByteString qualified as BS
import Data.Default (def)
import Data.Either (fromRight)
import Data.Foldable (traverse_)
import Data.Function (fix, (&))
import Data.Generics.Labels ()
import Data.HashMap.Strict qualified as Map
import Data.HashSet qualified as Set
import Data.Hashable
import Data.List (partition)
import Data.List qualified as DL
import Data.Maybe (fromJust, isJust, isNothing)
import Data.String (IsString (fromString))
import Data.String.Interpolate (i)
import Data.Text (pack)
import Data.Text qualified as Text
import Data.Text.Encoding (decodeUtf8)
import Data.Yaml (decodeFileEither)
import Data.Yaml.Pretty (defConfig, encodePretty)
import Extensions
import GHC.IO.Handle (BufferMode (NoBuffering), Handle, hSetBuffering)
import GHC.IO.IOMode (IOMode (AppendMode, WriteMode))
import Logger
import Main.Utf8 (withUtf8)
import Network.HTTP.Client (Response (..))
import Network.HTTP.Client.Conduit (Request (method))
import Network.HTTP.Simple (JSONException, httpJSONEither, setRequestBodyJSON, setRequestHeaders)
import Options.Generic
import Requests
import Turtle (Alternative (..), mktree, rm, testfile)
import Turtle.Bytes (shellStrictWithErr)
import UnliftIO (MonadUnliftIO (withRunInIO), STM, SomeException, TMVar, TVar, atomically, forConcurrently, mapConcurrently_, newTMVarIO, newTVarIO, putTMVar, readTVar, readTVarIO, stdout, takeTMVar, timeout, try, tryReadTMVar, withFile, writeTVar)
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
extLogger :: ToJSON a => FilePath -> TBMQueue a -> MyLogger ()
extLogger file queue = liftIO $
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

collectGarbageOnce :: MyLogger ()
collectGarbageOnce = do
  logInfo [i|#{START} Collecting garbage in /nix/store.|]
  (_, infoText, errText) <- shellStrictWithErr [i|nix store gc |] empty
  logInfo [i|#{infoText}|]
  logDebug [i|#{errText}|]
  logInfo [i|#{FINISH} Collecting garbage in /nix/store.|]

garbageCollector :: AppConfig' => TMVar () -> MyLogger ()
garbageCollector t = do
  t_ <- liftIO $ atomically $ tryReadTMVar t
  maybe
    (pure ())
    ( const $ do
        collectGarbageOnce
        liftIO $ threadDelay (?config.garbageCollectorDelay * _MICROSECONDS)
        garbageCollector t
    )
    t_

-- | Log info about the number of processed extensions
processedLogger :: AppConfig' => Int -> TMVar Int -> MyLogger ()
processedLogger total processed = flip fix 0 $ \ret n -> do
  p <- liftIO $ atomically $ tryReadTMVar processed
  traverse_
    ( \cnt -> do
        when (cnt /= n) $ logInfo [i|#{INFO} Processed (#{cnt}/#{total}) extensions|]
        liftIO $ threadDelay (?config.processedLoggerDelay * _MICROSECONDS)
        ret cnt
    )
    p

logAndForwardError :: MyLogger a -> String -> MyLogger a
logAndForwardError action message = action `catchAny` \error' -> logError [i|Error #{message}:\n#{error'}|] >> throw error'

-- | Get an extension from a target site and pass info about it to other threads
--
-- We do this by using the thread-safe data structures like special queues and vars
getExtension :: AppConfig' => Target -> TBMQueue ExtensionInfo -> TBMQueue ExtensionConfig -> TMVar Int -> TVar Int -> ExtensionConfig -> MyLogger ()
getExtension target extInfoQueue extFailedConfigQueue extProcessedN extFailedN extConfig@ExtensionConfig{platform, lastUpdated, missingTimes, engineVersion, version} = do
  let
    -- select an action for a target
    publisher = extConfig.publisher
    name = extConfig.name
    select :: a -> a -> a
    select = targetSelect target
    extName = [i|#{publisher}.#{name}|] :: Text
  logDebug [i|#{START} Requesting info about #{extName} from #{target}|]
  isFailed <- do
    let
      -- and prepare a url for a target site
      platformInfix :: Text =
        ( case platform of
            PUniversal -> ""
            x -> [i|/#{x}|]
        )
      platformSuffix :: Text =
        ( case platform of
            PUniversal -> ""
            x -> select [i|targetPlatform=#{x}|] [i|@#{x}|]
        )
      url :: Text
      url =
        select
          [i|https://#{publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/#{publisher}/extension/#{name}/#{version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?#{platformSuffix}|]
          [i|https://open-vsx.org/api/#{publisher}/#{name}#{platformInfix}/#{version}/file/#{extName}-#{version}#{platformSuffix}.vsix|]

    logDebug [i|#{START} Fetching #{extName} from #{url}|]
    -- let nix fetch a file from that url
    let timeout' = ?config.requestResponseTimeout
    (_, decodeUtf8 -> stdout', errText) <-
      let command = [i|nix store prefetch-file --timeout #{timeout'} --json #{url} --name #{extName}-#{version}-#{platform}|]
       in shellStrictWithErr command empty
            `logAndForwardError` [i|during prefetch-file: #{command}|]
    let sha256Maybe = stdout' ^? key "hash" . _String
    -- if stderr was non-empty, there was an error
    if not (BS.null errText)
      then do
        logInfo [i|#{FAIL} Fetching #{extName} from #{url}. The stderr:\n#{errText}|]
        pure True
      else case sha256Maybe of
        Nothing -> do
          logInfo [i|#{FAIL} Fetching #{extName} from #{url}. Could not parse JSON: #{stdout'}|]
          pure True
        Just sha256 -> do
          logInfo [i|#{FINISH} Fetching extension #{extName} from #{url}|]
          -- when everything is ok, we write the extension info into a queue
          -- this is to let other threads read from it
          liftIO $
            atomically $
              writeTBMQueue extInfoQueue $
                ExtensionInfo
                  { name
                  , publisher
                  , lastUpdated
                  , version
                  , platform
                  , missingTimes
                  , engineVersion
                  , sha256
                  }
          pure False
  -- if at some point we failed to obtain an extension info,
  -- we write its config into a queue for failed configs
  when
    isFailed
    do
      liftIO $ atomically $ writeTBMQueue extFailedConfigQueue extConfig
      liftIO $ atomically $ readTVar extFailedN >>= \x -> writeTVar extFailedN (x + 1)
  -- when finished, we update a shared counter
  liftIO $ atomically $ takeTMVar extProcessedN >>= \x -> putTMVar extProcessedN (x + 1)

data Key = Key
  { publisher :: Publisher
  , name :: Name
  , version :: Version
  , platform :: Platform
  , lastUpdated :: LastUpdated
  }
  deriving stock (Eq, Generic, Ord)
  deriving anyclass (Hashable)

whenM :: Monad m => m Bool -> m () -> m ()
whenM cond action = cond >>= (`when` action)

-- | Fetch the extensions given their configurations
runFetcher :: AppConfig' => FetcherConfig IO -> MyLogger ()
runFetcher
  -- TODO use OverloadedRecordDot
  FetcherConfig
    { target
    , queueCapacity
    , nThreads
    , cacheDir
    , mkTargetJSON
    , extConfigs
    , tmpDir
    } = do
    let
      fetchedTmpDir :: FilePath = [i|#{tmpDir}/fetched|]
      failedTmpDir :: FilePath = [i|#{tmpDir}/failed|]
    -- create directories for files with fetched, failed, and cached extensions
    -- just in case these directories don't exist
    forM_ [fetchedTmpDir, failedTmpDir, cacheDir] mktree
    -- if there were target files, remove them
    forM_ [fetchedTmpDir, failedTmpDir] (\(mkTargetJSON -> f) -> whenM (testfile f) (rm f))

    let extensionInfoCachedJSON = mkTargetJSON cacheDir

    -- if there is a file with cached info, we read it into a list
    extensionInfoCached <- withRunInIO $ \runInIO ->
      ( eitherDecodeFileStrict' extensionInfoCachedJSON
          >>= \case
            Left err -> runInIO $ logError (pack $ show err) >> pure []
            Right v -> pure v
      )
        `catchAny` (\err -> runInIO $ logError (pack $ show err) >> pure [])

    let mkKeyInfo
          ExtensionInfo
            { publisher
            , name
            , version
            , platform
            , lastUpdated
            } =
            Key
              { publisher
              , name
              , version
              , platform
              , lastUpdated
              }
        mkKeyConfig
          ExtensionConfig
            { publisher
            , name
            , version
            , platform
            , lastUpdated
            } =
            Key
              { publisher
              , name
              , version
              , platform
              , lastUpdated
              }
        -- we load the cached info into a map for quicker access
        extensionInfoCacheMap = Map.fromList ((\d -> (mkKeyInfo d, d)) <$> extensionInfoCached)
        -- also, we filter out the duplicates among the extension configs
        configsSorted = Set.toList . Set.fromList $ extConfigs
        -- we partition the extension configs depending on if they're present in a cache
        (presentExtensionInfo, extensionConfigsMissing) =
          (partition (isJust . fst) ((\c -> (Map.lookup (mkKeyConfig c) extensionInfoCacheMap, c)) <$> configsSorted))
            & bimap ((\x -> x & #missingTimes .~ 0) . fromJust . fst <$>) (snd <$>)
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
        extensionInfoMissingConfigs =
          extensionInfoMissing
            <&> ( \ExtensionInfo
                    { name
                    , publisher
                    , lastUpdated
                    , version
                    , platform
                    , missingTimes
                    , engineVersion
                    } ->
                      ExtensionConfig
                        { name
                        , publisher
                        , lastUpdated
                        , version
                        , platform
                        , missingTimes
                        , engineVersion
                        }
                )
        -- combine new and old missing configs
        extensionConfigsMissing' = extensionConfigsMissing <> extensionInfoMissingConfigs
        -- and calculate the number of the configs of extensions that are missing
        numberExtensionConfigsMissing = length extensionConfigsMissing'
    -- collect extensions from cache that are not present
    traverse_
      logInfo
      [ [i|#{START} Running a fetcher on #{target}|]
      , [i|#{INFO} From #{target} have #{length extensionInfoCached} cached extensions|]
      , [i|#{INFO} There are #{length extensionConfigsMissing} new extension configs.|]
      , [i|#{INFO} From #{length extensionInfoCached} cached extensions, #{length extensionInfoMissing} are not among the extensions available at #{target}.|]
      , [i|#{START} Updating cached info about #{numberExtensionConfigsMissing} extension(s) from #{target}|]
      ]

    -- we prepare shared queues and variables
    extInfoQueue <- liftIO $ newTBMQueueIO queueCapacity
    extFailedConfigQueue <- liftIO $ newTBMQueueIO queueCapacity
    -- this is a counter of processed extensions
    -- it should become empty when all extensions are processed
    extProcessedN <- newTMVarIO 0
    extProcessedNFinal <- newTVarIO 0
    extFailedN <- newTVarIO 0
    -- flag for garbage collector
    collectGarbage <- newTMVarIO ()

    unless ?config.collectGarbage (atomically $ takeTMVar collectGarbage)

    -- we prepare file names where threads will write to
    let fetchedExtensionInfoFile = mkTargetJSON fetchedTmpDir
        failedExtensionConfigFile = mkTargetJSON failedTmpDir

    -- and run together
    ( mapConcurrently_
        id
        [ -- a logger of info about the number of successfully processed extensions
          processedLogger numberExtensionConfigsMissing extProcessedN
            `logAndForwardError` [i|in "processed" logger thread|]
        , -- a logger that writes the info about successfully fetched extensions into a file
          extLogger fetchedExtensionInfoFile extInfoQueue
            `logAndForwardError` [i|in "fetched" logger thread|]
        , -- a logger that writes the info about failed extensions into a file
          extLogger failedExtensionConfigFile extFailedConfigQueue
            `logAndForwardError` [i|in "failed" logger thread|]
        , -- a garbage collector
          garbageCollector collectGarbage
            `logAndForwardError` [i|in "garbage collector" thread|]
        , -- and an action that uses a thread pool to fetch the extensions
          -- it's more efficient than spawning a thread per each element of a list with extensions' configs
          withRunInIO
            ( \runInIO ->
                withTaskGroup nThreads $ \g -> do
                  void
                    ( mapConcurrently
                        g
                        (runInIO . getExtension target extInfoQueue extFailedConfigQueue extProcessedN extFailedN)
                        extensionConfigsMissing'
                    )
            )
            `logAndForwardError` [i|in "worker" threads|]
            `finally` do
              -- when all configs are processed, we need to close both queues
              -- this will let loggers know that they should quit
              atomically $ closeTBMQueue extInfoQueue
              atomically $ closeTBMQueue extFailedConfigQueue
              -- make this var empty to notify the threads reading from it
              -- clone its value
              atomically $ takeTMVar extProcessedN >>= writeTVar extProcessedNFinal
              -- also, stop the garbage collector
              when ?config.collectGarbage do
                atomically $ takeTMVar collectGarbage
                collectGarbageOnce
        ]
      )
      -- even if there are some errors
      -- we want to finally append the info about the newly fetched extensions to the cache
      `finally` do
        logInfo [i|#{START} Caching updated info about extensions from #{target}|]
        -- we combine into a sorted list the cached info and the new info that we read from a file
        extSorted <-
          DL.sortBy (\x y -> compare (mkKeyInfo x) (mkKeyInfo y))
            . (<> presentExtensionInfo)
            . fromRight []
            <$> liftIO (eitherDecodeFileStrict' fetchedExtensionInfoFile)
        -- after that, we compactly write the extensions info

        liftIO
          ( withFile extensionInfoCachedJSON WriteMode $ \h -> do
              BS.hPutStr h "[ "
              case extSorted of
                [] -> pure ()
                xs -> encodeFirstList h xs
              BS.hPutStr h "]"
          )
          `logAndForwardError` "when writing extensions to file"
        logInfo [i|#{FINISH} Caching updated info about extensions from #{target}|]
        extProcessedNFinal' <- readTVarIO extProcessedNFinal
        extFailedN' <- readTVarIO extFailedN
        logInfo [i|#{INFO} Processed #{extProcessedNFinal'}, failed #{extFailedN'} extensions|]
        logInfo [i|#{FINISH} Running a fetcher on #{target}|]

-- | Retry an action a given number of times with a given delay and log about its status
retry_ :: (MonadUnliftIO m, Alternative m, WithLog (LogAction m msg) Message m, AppConfig') => Int -> Text -> m b -> m b
retry_ nAttempts msg action
  | nAttempts >= 0 =
      let retryDelay = ?config.retryDelay
          action_ n = do
            let n_ = nAttempts - n + 1
            res <- try (action >>= \res -> logDebug [i|#{INFO} Attempt (#{n_}/#{nAttempts}) succeeded. Continuing.|] >> pure res)
            case res of
              Left (err :: SomeException)
                | n >= 1 -> do
                    logError [i|#{FAIL} (#{n_}/#{nAttempts}) #{msg}.\nError:\n#{err}\nRetrying in #{retryDelay} seconds.|]
                    liftIO (threadDelay (?config.retryDelay * _MICROSECONDS))
                    action_ (n - 1)
                | otherwise -> do
                    logError [i|#{ABORT} All #{nAttempts} attempts have failed. #{msg}|]
                    throw err
              Right r -> pure r
       in action_ nAttempts
  | nAttempts < 0 = error [i|retry_: count must be 0 or more.\nCount: #{nAttempts}|]
retry_ _ _ _ = error "retry_: count must be 0 or more."

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

filteredExtensions :: Traversal' Value Value
filteredExtensions =
  key "results"
    . nth 0
    . key "extensions"
    . _Array
    . traversed
    . filteredByFlags

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
getConfigs :: AppConfig' => Target -> MyLogger [ExtensionConfig]
getConfigs target =
  let nRetry = ?config.nRetry
      siteConfig = targetSelect target ?config.vscodeMarketplace ?config.openVSX
   in retry_ nRetry [i|Collecting the extension configs from #{target}|] do
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
                      , pageNumber
                      , pageSize
                      }
                  ]
              , assetTypes = []
              , flags = 946
              }
        logInfo [i|#{START} Collecting the latest versions of extensions|]
        logInfo [i|#{START} Collecting #{pageCount} page(s) of size #{pageSize}.|]
        -- we request the pages of extensions from VSCode Marketplace concurrently
        pages <- traverse responseBody <$> liftIO (forConcurrently [1 .. pageCount] (mkEitherRequest target . requestExtensionsList))
        case pages of
          -- if we were unsuccessful, we need to retry
          Left l -> logError [i|#{FAIL} Getting info about extensions from #{target}|] >> error [i|#{l}|]
          Right r -> do
            pure $
              r
                ^.. traversed
                  . filteredExtensions
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
                                            pure
                                              ExtensionConfig
                                                { engineVersion = fromJust engineVersion
                                                , name
                                                , publisher
                                                , lastUpdated
                                                , version
                                                , platform
                                                , missingTimes
                                                }
                                        )
                                    )
                                  . _Just
                        )
                    )
                  . _Just
                  . traversed

-- | Get a list of extension configs from VSCode Marketplace
getConfigsRelease :: AppConfig' => Target -> MyLogger [ExtensionConfig]
getConfigsRelease target = do
  logInfo [i|#{START} Collecting the release versions of extensions|]
  let nRetry = ?config.nRetry
      siteConfig = targetSelect target ?config.vscodeMarketplace ?config.openVSX
   in retry_ nRetry [i|Collecting the release extension configs from #{target}|] do
        let
          extensionCriteria =
            siteConfig.release.releaseExtensions
              ^.. traversed
                . to
                  ( \ReleaseExtension
                      { publisher
                      , name
                      } ->
                        Criterion
                          { filterType = 7
                          , value = [i|#{publisher}.#{name}|]
                          }
                  )
          pageSize = length extensionCriteria
          requestExtensionsList =
            Req
              { filters =
                  [ Filter
                      { criteria =
                          [ Criterion
                              { filterType = 8
                              , value = "Microsoft.VisualStudio.Code"
                              }
                          ]
                            <> extensionCriteria
                      , sortBy = 0
                      , sortOrder = 0
                      , pageNumber = 1
                      , pageSize
                      }
                  ]
              , assetTypes = []
              , flags = 1073
              }
        logInfo [i|#{START} Collecting release extension pages.|]
        pages <- responseBody <$> liftIO (mkEitherRequest target requestExtensionsList)
        case pages of
          -- if we were unsuccessful, we need to retry
          Left l -> logError [i|#{FAIL} Getting info about extensions from #{target}|] >> error [i|#{l}|]
          Right r -> do
            pure $
              r
                ^.. filteredExtensions
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
                                                pure
                                                  ExtensionConfig
                                                    { engineVersion = fromJust engineVersion
                                                    , missingTimes
                                                    , name
                                                    , publisher
                                                    , lastUpdated
                                                    , version
                                                    , platform
                                                    }
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
runCrawler :: AppConfig' => CrawlerConfig IO -> MyLogger ([ExtensionConfig], [ExtensionConfig])
runCrawler CrawlerConfig{target} =
  do
    logInfo [i|#{START} Updating info about extensions from #{target}.|]
    -- we select the target crawler and run it
    -- on release configs
    configsRelease <- getConfigsRelease target

    -- print the obtained release configs
    logDebug [i|#{configsRelease}|]

    -- on all configs
    configs <- getConfigs target

    logInfo [i|#{FINISH} Updating info about extensions from #{target}.|]
    -- finally, we return the configs
    pure (configs, configsRelease)

processTarget :: AppConfig' => ProcessTargetConfig IO -> MyLogger ()
processTarget
  -- TODO use OverloadedRecordDot
  ProcessTargetConfig
    { target
    , dataDir
    , logger
    , nThreads
    , queueCapacity
    } =
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
      (configs, configsRelease) <-
        runCrawler
          CrawlerConfig
            { target
            , nRetry
            , logger
            }
          `logAndForwardError` "when running crawler"

      -- then, we run a fetcher
      runFetcher
        FetcherConfig
          { extConfigs = configsRelease
          , mkTargetJSON = mkTargetReleaseJSON
          , nThreads
          , queueCapacity
          , target
          , cacheDir
          , logger
          , tmpDir
          }
        `logAndForwardError` "when running fetcher for release extensions"
      runFetcher
        FetcherConfig
          { extConfigs = configs
          , target
          , nThreads
          , queueCapacity
          , cacheDir
          , mkTargetJSON
          , logger
          , tmpDir
          }
        `logAndForwardError` "when running fetcher for latest extensions"
      -- in case of errors, rethrow an exception
      `logAndForwardError` [i|when requesting #{target}|]

newtype ConfigOptions w = ConfigOptions
  { config :: w ::: Maybe FilePath <?> "Path to a config file"
  }
  deriving stock (Generic)

instance ParseRecord (ConfigOptions Wrapped)
deriving anyclass instance ParseRecord (ConfigOptions Unwrapped)

main :: IO ()
main = withUtf8 do
  configOptions :: (ConfigOptions Unwrapped) <- unwrapRecord "Updater"
  -- we'll let logs be written to stdout as soon as they come
  hSetBuffering stdout NoBuffering
  config_ <-
    case configOptions.config of
      Nothing -> putStrLn [i|No path to config file specified. Using the default config.|] >> pure (mkDefaultAppConfig def)
      Just s -> do
        appConfig <- decodeFileEither s
        case appConfig of
          Left err -> error [i|Could not decode the config file\n\n#{err}. Aborting.|]
          Right appConfig_ -> pure $ mkDefaultAppConfig appConfig_

  void $
    timeout (config_.programTimeout * _MICROSECONDS) $
      let ?config = config_
       in do
            -- TODO use OverloadedRecordDot
            let AppConfig
                  { dataDir
                  , queueCapacity
                  , logSeverity
                  , vscodeMarketplace
                  , openVSX
                  } = config_
            withBackgroundLogger @IO defCapacity (cfilter (\(Msg sev _ _) -> sev >= logSeverity) $ formatWith fmtMessage logTextStdout) (pure ()) $ \logger -> usingLoggerT logger do
              logInfo [i|#{START} Updating extensions|]
              logInfo [i|#{START} Config:\n#{encodePretty defConfig config_}|]
              -- we'll run the extension crawler and a fetcher a given number of times on both target sites
              traverse_
                ( \target ->
                    _myLoggerT
                      ( retry_
                          ?config.runN
                          [i|Processing #{target}|]
                          ( processTarget
                              ProcessTargetConfig
                                { dataDir = dataDir
                                , nThreads = targetSelect target vscodeMarketplace.nThreads openVSX.nThreads
                                , queueCapacity = queueCapacity
                                , target
                                , logger
                                }
                          )
                      )
                )
                ([VSCodeMarketplace | ?config.vscodeMarketplace.enable] <> [OpenVSX | ?config.openVSX.enable])
              logInfo [i|#{FINISH} Updating extensions|]
