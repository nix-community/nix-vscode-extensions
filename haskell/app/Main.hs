{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE MultiWayIf #-}

module Main (main) where

import Colog (LogAction (..), Message, Msg (..), WithLog, cfilter, fmtMessage, formatWith, logDebug, logError, logInfo, logTextStdout, usingLoggerT)
import Colog.Concurrent (defCapacity, withBackgroundLogger)
import Configs (AppConfig (..), Settings, SiteConfig (..), TargetSettings, mkDefaultAppConfig, _MICROSECONDS)
import Control.Applicative (Alternative)
import Control.Concurrent.Async.Pool qualified as AsyncPool (mapConcurrently, withTaskGroup)
import Control.Concurrent.STM.TBMQueue (TBMQueue, closeTBMQueue, newTBMQueueIO, peekTBMQueue, tryReadTBMQueue, writeTBMQueue)
import Control.Concurrent.Thread.Delay (delay)
import Control.Concurrent.Timeout (Timeout, timeout)
import Control.Lens (Bifunctor (bimap), Traversal', filtered, has, non, only, to, traversed, (%~), (+~), (.~), (<&>), (^.), (^..), (^?), _2, _Empty, _Just, _Left, _Right)
import Control.Lens.Extras (is)
import Control.Monad (forM_, guard, unless, void, when)
import Control.Monad.IO.Class (MonadIO (..))
import Data.Aeson (ToJSON, Value (..), withObject, (.:), (.:?))
import Data.Aeson qualified as Aeson
import Data.Aeson.Lens (key, nth, _Array, _String)
import Data.Aeson.Types (parseMaybe)
import Data.Bits (Bits (..))
import Data.ByteString qualified as BS
import Data.Coerce (coerce)
import Data.Default (def)
import Data.Foldable (foldr', traverse_)
import Data.Function (fix, (&))
import Data.Generics.Labels ()
import Data.HashMap.Strict (HashMap)
import Data.HashMap.Strict qualified as HashMap
import Data.HashSet qualified as HashSet
import Data.List (intersect, partition, sortOn)
import Data.Maybe (fromJust, isJust, isNothing)
import Data.String (IsString (fromString))
import Data.Text qualified as T
import Data.Text qualified as Text
import Data.Yaml (decodeFileThrow)
import Data.Yaml.Pretty (defConfig, encodePretty)
import Extensions
import GHC.IO.Handle (BufferMode (NoBuffering), Handle, hSetBuffering)
import GHC.IO.IOMode (IOMode (AppendMode, WriteMode))
import Logger (ActionStatus (..), MyLogger, MyLoggerT (..))
import Main.Utf8 (withUtf8)
import Network.HTTP.Client (Response (..))
import Network.HTTP.Client.Conduit (Request (method))
import Network.HTTP.Simple (JSONException, httpJSONEither, setRequestBodyJSON, setRequestHeaders)
import Options.Generic
import Prettyprinter (Pretty (..))
import PyF (fmt)
import Requests (Criterion (..), Filter (..), Req (..))
import System.Directory as Directory (createDirectoryIfMissing, doesFileExist, removeFile)
import UnliftIO (Exception (fromException), MonadUnliftIO (withRunInIO), STM, TMVar, TVar, atomically, mapConcurrently_, newTMVarIO, newTVarIO, putTMVar, readTVar, readTVarIO, stdout, takeTMVar, throwIO, tryAny, tryReadTMVar, withFile, writeTVar)
import UnliftIO.Exception (catchAny, finally)
import UnliftIO.Process (readCreateProcessWithExitCode, shell)

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
encodeFirstList :: (ToJsonBs a) => Handle -> [a] -> IO ()
encodeFirstList h (x : xs) = do
  BS.hPutStr h ([fmt|{toJsonBs x}\n|])
  traverse_ (\y -> BS.hPutStr h ([fmt|, {toJsonBs y}\n|])) xs
encodeFirstList _ [] = pure ()

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
extLogger :: forall a. (ToJsonBs a) => FilePath -> TBMQueue a -> MyLogger ()
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
              traverse_ (traverse_ (\x -> BS.hPutStr h [fmt|, {toJsonBs x}\n|])) extData
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
  logInfo [fmt|{START} Collecting garbage in /nix/store.|]
  (_, infoText, errText) <-
    readCreateProcessWithExitCode (shell [fmt|nix store gc |]) ""
  logInfo [fmt|{infoText}|]
  logDebug [fmt|{errText}|]
  logInfo [fmt|{FINISH} Collecting garbage in /nix/store.|]

garbageCollector :: (?garbageCollectorDelay :: Int) => TMVar () -> MyLogger ()
garbageCollector t = do
  t_ <- liftIO $ atomically $ tryReadTMVar t
  maybe
    (pure ())
    ( const $ do
        collectGarbageOnce
        liftIO $ delay (fromIntegral ?garbageCollectorDelay * _MICROSECONDS)
        garbageCollector t
    )
    t_

-- | Log info about the number of processed extensions
processedLogger :: (?processedLoggerDelay :: Int) => Int -> TMVar Int -> MyLogger ()
processedLogger total processed = flip fix 0 $ \ret n -> do
  p <- liftIO $ atomically $ tryReadTMVar processed
  traverse_
    ( \cnt -> do
        when (cnt /= n) $ logInfo [fmt|{INFO} Processed ({cnt}/{total}) extensions|]
        liftIO $ delay (fromIntegral ?processedLoggerDelay * _MICROSECONDS)
        ret cnt
    )
    p

logAndForwardError :: MyLogger a -> String -> MyLogger a
logAndForwardError action message =
  action
    `catchAny` \error' -> do
      logError [fmt|Error {message}:\n{show error'}|]
      throwIO error'

-- | Get an extension from a target site and pass info about it to other threads
--
-- We do this by using the thread-safe data structures like special queues and vars
getExtension ::
  (?requestResponseTimeout :: Int) =>
  Target ->
  TBMQueue ExtensionInfo ->
  TBMQueue ExtensionConfig ->
  TMVar Int ->
  TVar Int ->
  ExtensionConfig ->
  MyLogger ()
getExtension
  target
  extInfoQueue
  extFailedConfigQueue
  extProcessedN
  extFailedN
  extConfig@ExtensionConfig
    { publisher
    , name
    , version
    , platform
    , engineVersion
    , isRelease
    } = do
    let
      select :: a -> a -> a
      select = targetSelect target
      extName = [fmt|{publisher}.{name}|] :: Text
    logDebug [fmt|{START} Requesting info about {extName} from {target}|]
    isFailed <- do
      let
        -- and prepare a url for a target site
        platformInfix :: Text =
          ( case platform of
              PUniversal -> ""
              x -> [fmt|/{x}|]
          )
        platformSuffix :: Text =
          ( case platform of
              PUniversal -> ""
              x -> select [fmt|targetPlatform={x}|] [fmt|@{x}|]
          )
        url :: Text
        url =
          select
            [fmt|https://{publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/{publisher}/extension/{name}/{version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?{platformSuffix}|]
            [fmt|https://open-vsx.org/api/{publisher}/{name}{platformInfix}/{version}/file/{extName}-{version}{platformSuffix}.vsix|]

      logDebug [fmt|{START} Fetching {extName} from {url}|]
      -- let nix fetch a file from that url
      let timeout' = ?requestResponseTimeout
      (_, stdoutStr, stderrStr) <-
        let command = [fmt|nix store prefetch-file --timeout {timeout'} --json {url} --name {extName}-{version}-{platform}|]
         in readCreateProcessWithExitCode (shell command) ""
              `logAndForwardError` [fmt|during prefetch-file: {command}|]
      let hashMaybe = stdoutStr ^? key "hash" . _String
      -- if stderr was non-empty, there was an error
      if not (null stderrStr)
        then do
          logInfo [fmt|{FAIL} Fetching {extName} from {url}. The stderr:\n{stderrStr}|]
          pure True
        else case hashMaybe of
          Nothing -> do
            logInfo [fmt|{FAIL} Fetching {extName} from {url}. Could not parse JSON: {stdoutStr}|]
            pure True
          Just hash -> do
            logInfo [fmt|{FINISH} Fetching extension {extName} from {url}|]
            -- When everything is ok, we write the extension info into a queue.
            -- Other threads will read from it.
            liftIO $
              atomically $
                writeTBMQueue extInfoQueue $
                  ExtensionInfo
                    { name
                    , publisher
                    , version
                    , platform
                    , -- , missingTimes = 0
                      engineVersion
                    , hash
                    , isRelease
                    }
            pure False
    -- if at some point we failed to obtain an extension info,
    -- we write its config into a queue for failed configs
    when
      isFailed
      do
        liftIO $ atomically $ writeTBMQueue extFailedConfigQueue extConfig
        liftIO $ atomically do
          extFailedN' <- readTVar extFailedN
          writeTVar extFailedN (extFailedN' + 1)
    -- when finished, we update a shared counter
    liftIO $ atomically do
      extProcessedN' <- takeTMVar extProcessedN
      putTMVar extProcessedN (extProcessedN' + 1)

writeJsonCompact :: (ToJsonBs a) => FilePath -> [a] -> IO ()
writeJsonCompact path vals =
  withFile path WriteMode $ \h ->
    do
      BS.hPutStr h "[ "
      case vals of
        [] -> pure ()
        xs -> encodeFirstList h xs
      BS.hPutStr h "]"

writeDebugJsonCompact :: (ToJsonBs a, ?target :: Target, ?debugDir :: FilePath) => FilePath -> [a] -> IO ()
writeDebugJsonCompact suffix = writeJsonCompact (mkTargetJson ?target ?debugDir suffix)

-- | Fetch the extension info given their configs
runInfoFetcher ::
  ( TargetSettings
  , ?mkTargetLatestJson :: FilePath -> FilePath
  , ?extensionInfoCachePath :: FilePath
  ) =>
  [ExtensionInfo] ->
  [ExtensionConfig] ->
  MyLogger ()
runInfoFetcher extensionInfoCached extensionConfigs =
  do
    let
      target = ?target

    -- if there were target files, remove them
    forM_
      [?fetchedDir, ?failedDir]
      ( \(?mkTargetLatestJson -> f) -> do
          existsFile <- liftIO (Directory.doesFileExist f)
          when existsFile (liftIO (Directory.removeFile f))
      )

    let
      mkKey x = (x.publisher, x.name, x.isRelease, x.platform, x.version)

      -- We load the cached info into a map for quicker access
      extensionInfoCachedMap =
        HashMap.fromList ((\d -> (mkKey d, d)) <$> extensionInfoCached)

      -- Also, we filter out the duplicates among the extension configs
      extensionConfigsUnique = HashSet.toList . HashSet.fromList $ extensionConfigs

      -- We determine which fetched configs do and don't have corresponding cached info.
      -- We map those that do to that corresponding cached info.
      -- We reset the missing times counter for them.
      (extensionInfoCachedAndFetched, extensionConfigsFetchedNotCached) =
        ( partition
            (isJust . fst)
            ( (\c -> (HashMap.lookup (mkKey c) extensionInfoCachedMap, c))
                <$> extensionConfigsUnique
            )
        )
          & bimap
            ( -- (\x -> x & #missingTimes .~ 0)
              -- .
              fromJust
                . fst
                <$>
            )
            (snd <$>)

      extensionInfoCachedAndFetchedMap =
        HashMap.fromList ((\d -> (mkKey d, d)) <$> extensionInfoCachedAndFetched)

      -- We identify cached info that has no corresponding fetched configs.
      -- We increment counters for such info.
      extensionInfoCachedNotFetched =
        extensionInfoCached
          ^.. traversed
            . filtered
              ( \c ->
                  (isNothing $ HashMap.lookup (mkKey c) extensionInfoCachedAndFetchedMap)
                  -- && (c.missingTimes + 1 < ?maxMissingTimes)
              )
      -- & traversed . #missingTimes +~ 1

      -- and calculate the number of the configs of extensions that are missing
      numberExtensionConfigsFetchedNotCached = length extensionConfigsFetchedNotCached

    liftIO do
      writeDebugJsonCompact "info-present-and-fetched" extensionInfoCachedAndFetched
      writeDebugJsonCompact "configs-fetched-not-cached" extensionConfigsFetchedNotCached

    traverse_
      logInfo
      [ [fmt|{INFO} We have cached info for {length extensionInfoCached} extensions.|]
      , [fmt|{INFO} {length extensionConfigsFetchedNotCached} fetched configs have no corresponding cached info.|]
      , [fmt|{START} Running a fetcher on {target}.|]
      , [fmt|{INFO} Fetching {length extensionConfigsFetchedNotCached} extensions.|]
      ]

    -- we prepare shared queues and variables
    extInfoQueue <- liftIO $ newTBMQueueIO ?queueCapacity
    extFailedConfigQueue <- liftIO $ newTBMQueueIO ?queueCapacity
    -- this is a counter of processed extensions
    -- it should become empty when all extensions are processed
    extProcessedN <- newTMVarIO 0
    extProcessedNFinal <- newTVarIO 0
    extFailedN <- newTVarIO 0
    -- flag for garbage collector
    collectGarbage <- newTMVarIO ()

    unless ?collectGarbage (atomically $ takeTMVar collectGarbage)

    -- we prepare file names where threads will write to
    let fetchedExtensionInfoFile = ?mkTargetLatestJson ?fetchedDir
        failedExtensionConfigFile = ?mkTargetLatestJson ?failedDir

    -- and run together
    ( mapConcurrently_
        id
        [ -- a logger of info about the number of successfully processed extensions
          processedLogger numberExtensionConfigsFetchedNotCached extProcessedN
            `logAndForwardError` [fmt|in "processed" logger thread|]
        , -- a logger that writes the info about successfully fetched extensions into a file
          extLogger fetchedExtensionInfoFile extInfoQueue
            `logAndForwardError` [fmt|in "fetched" logger thread|]
        , -- a logger that writes the info about failed extensions into a file
          extLogger failedExtensionConfigFile extFailedConfigQueue
            `logAndForwardError` [fmt|in "failed" logger thread|]
        , -- a garbage collector
          garbageCollector collectGarbage
            `logAndForwardError` [fmt|in "garbage collector" thread|]
        , -- and an action that uses a thread pool to fetch the extensions
          -- it's more efficient than spawning a thread per each element of a list with extensions' configs
          withRunInIO
            ( \runInIO ->
                AsyncPool.withTaskGroup ?threadNumber $ \g -> do
                  void
                    ( AsyncPool.mapConcurrently
                        g
                        (runInIO . getExtension target extInfoQueue extFailedConfigQueue extProcessedN extFailedN)
                        extensionConfigsFetchedNotCached
                    )
            )
            `logAndForwardError` [fmt|in "worker" threads|]
            `finally` do
              -- when all configs are processed, we need to close both queues
              -- this will let loggers know that they should quit
              atomically $ closeTBMQueue extInfoQueue
              atomically $ closeTBMQueue extFailedConfigQueue
              -- make this var empty to notify the threads reading from it
              -- clone its value
              atomically $ takeTMVar extProcessedN >>= writeTVar extProcessedNFinal
              -- also, stop the garbage collector
              when ?collectGarbage do
                atomically $ takeTMVar collectGarbage
                collectGarbageOnce
        ]
      )
      -- Even if there are some errors,
      -- we want to finally update the cached info
      `finally` do
        logInfo [fmt|{START} Caching updated info about extensions from {target}.|]

        extensionInfoFetched <- decodeFile fetchedExtensionInfoFile "[ ]"

        -- We need new fetched info to override old cached info.
        -- `HashMap.unions` keeps elements of maps
        -- that are closer to the head of the list.
        let mkKey' x = (x.publisher, x.name, x.isRelease, x.platform)

            extensionInfoUpdated =
              HashMap.elems $
                HashMap.unions $
                  HashMap.fromList
                    . ((\x -> (mkKey' x, x)) <$>)
                    <$> [ extensionInfoFetched
                        , extensionInfoCachedNotFetched
                        , extensionInfoCachedAndFetched
                        ]

            extensionInfoSorted =
              sortOn mkKey extensionInfoUpdated

        -- after that, we compactly write the extensions info
        liftIO
          (writeJsonCompact ?extensionInfoCachePath extensionInfoSorted)
          `logAndForwardError` "when writing extensions to file"

        let
          extensionInfoCached' = HashSet.fromList extensionInfoCached
          extensionInfoUpdated' = HashSet.fromList extensionInfoUpdated

          mkFun fun a b =
            sortOn mkKey $
              HashSet.toList $
                fun a b

          mkDiff = mkFun HashSet.difference

          cachedNotUpdated = mkDiff extensionInfoCached' extensionInfoUpdated'

          updatedNotCached = mkDiff extensionInfoUpdated' extensionInfoCached'

          cachedAndUpdated = mkFun HashSet.intersection extensionInfoCached' extensionInfoUpdated'

        liftIO do
          writeDebugJsonCompact "cached-not-updated" cachedNotUpdated
          writeDebugJsonCompact "updated-not-cached" updatedNotCached
          writeDebugJsonCompact "cached-and-updated" cachedAndUpdated

        logInfo [fmt|{FINISH} Caching updated info about extensions from {target}.|]
        extProcessedNFinal' <- readTVarIO extProcessedNFinal
        extFailedN' <- readTVarIO extFailedN
        logInfo [fmt|{INFO} Processed {extProcessedNFinal'}, failed {extFailedN'} extensions|]
        logInfo [fmt|{FINISH} Running a fetcher on {target}|]

-- | Retry an action a given number of times with a given delay and logs about its status
retry_ :: (MonadUnliftIO m, Alternative m, WithLog (LogAction m msg) Message m, (?retryDelay :: Int, ?programTimeout :: Int)) => Int -> Text -> m b -> m b
retry_ nAttempts msg action
  | nAttempts >= 0 =
      let retryDelay = ?retryDelay
          action_ n = do
            let n_ = nAttempts - n + 1
            res <- tryAny do
              res <- action
              logDebug [fmt|{INFO} Attempt {n_} of {nAttempts} succeeded. Continuing.|]
              pure res
            case res of
              Left err ->
                if
                  | -- Handle the asynchronous Timeout exception.
                    Just _ <- fromException @Timeout err -> do
                      let seconds = ?programTimeout
                      logError [fmt|{ABORT} Attempt {n_} of {nAttempts}. Timed out in {seconds} seconds.|]
                      throwIO err
                  | n >= 1 -> do
                      logError [fmt|{FAIL} Attempt {n_} of {nAttempts}. {msg}.\nError:\n{show err}\nRetrying in {retryDelay} seconds.|]
                      liftIO (delay (fromIntegral retryDelay * _MICROSECONDS))
                      action_ (n - 1)
                  | otherwise -> do
                      logError [fmt|{ABORT} All {nAttempts} attempts have failed. {msg}|]
                      throwIO err
              Right r -> pure r
       in action_ nAttempts
  | otherwise = error [fmt|retry_: nAttempts must be 0 or more.\nCount: {nAttempts}|]

filteredByFlags :: Traversal' Value Value
filteredByFlags =
  filtered
    ( \y ->
        let flags z = filter (not . Text.null) (Text.splitOn ", " z)
         in maybe
              False
              -- check if all flags are allowed
              (\z -> length (flags z) == length (flags z & intersect extFlagsAllowed))
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

mkRequest :: (ToJSON a) => Target -> a -> Request
mkRequest target requestBody =
  setRequestBodyJSON requestBody
    $ setRequestHeaders
      [ ("CONTENT-TYPE", "application/json")
      , ("ACCEPT", "application/json; api-version=6.1-preview.1")
      , ("ACCEPT-ENCODING", "gzip")
      ]
    $ (fromString (apiUrl target)){method = "POST"}

requestJsonEither :: (MonadIO w, ToJSON a) => Target -> a -> w (Response (Either JSONException Value))
requestJsonEither target requestBody = httpJSONEither @_ @Value (mkRequest target requestBody)

-- | A request flag value.
--
-- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L158
--
-- https://github.com/eclipse/openvsx/blob/d02ca60957c0281671fd7e1cad0ebb147e14aa21/server/src/main/java/org/eclipse/openvsx/adapter/ExtensionQueryParam.java#L26
flag'ExcludeNonValidated, flag'IncludeLatestPrereleaseAndStableVersionOnly, flag'IncludeVersionProperties, flag'IncludeLatestVersionOnly :: Int
flag'IncludeVersionProperties = 0x10
flag'ExcludeNonValidated = 0x20
flag'IncludeLatestVersionOnly = 0x200
-- Supported by VS Code Marketplace
-- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L212
--
-- Not supported by Open VSX
-- https://github.com/eclipse/openvsx/blob/d02ca60957c0281671fd7e1cad0ebb147e14aa21/server/src/main/java/org/eclipse/openvsx/adapter/ExtensionQueryParam.java#L35
flag'IncludeLatestPrereleaseAndStableVersionOnly = 0x10000

-- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L204C1-L204C28
flag'Unpublished :: Int
flag'Unpublished = 0x1000

orFlags :: [Int] -> Int
orFlags = foldr (.|.) 0

partitionEithersOn :: (f (Either a b) -> Maybe (f a)) -> (f (Either a b) -> Maybe (f b)) -> [f (Either a b)] -> ([f a], [f b])
partitionEithersOn pl pr =
  foldr'
    ( \x (ls, rs) ->
        case pl x of
          Nothing ->
            case pr x of
              Nothing -> error "Impossible"
              Just x' -> (ls, x' : rs)
          Just x' -> (x' : ls, rs)
    )
    ([], [])

-- | Get a list of extension configs from the target marketplace.
getExtensionConfigs :: (TargetSettings) => MyLogger [ExtensionConfig]
getExtensionConfigs = do
  let target = ?target
      nRetry = ?nRetry
      siteConfig = targetSelect target ?vscodeMarketplace ?openVSX

  retry_ nRetry [fmt|Collecting the extension configs from {target}|] do
    let
      pageCount = siteConfig.pageCount
      pageSize = siteConfig.pageSize
      requestExtensionsList pageNumber =
        Req
          { filters =
              [ Filter
                  { criteria =
                      -- here are these criteria in the original code
                      -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryService.ts#L1276

                      -- here's where filters are converted to numbers
                      -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryService.ts#L1291
                      --
                      -- here's the mapping of filters to numbers
                      -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L88
                      -- TODO update and explain
                      [ Criterion
                          { filterType = 8
                          , value = "Microsoft.VisualStudio.Code"
                          }
                      , Criterion
                          { filterType = 12
                          , -- Should be a text for some reason
                            -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryService.ts#L1284
                            value = T.show flag'Unpublished
                          }
                      ]
                  , -- Title
                    -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L133C18-L133C23
                    sortBy = 2
                  , -- Ascending
                    -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionManagement.ts#L302
                    sortOrder = 2
                  , pageNumber
                  , pageSize
                  }
              ]
          , assetTypes = []
          , -- flags are OR-ed
            -- https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryService.ts#L1310
            flags =
              orFlags
                [ -- TODO remove this flag
                  --
                  -- If we assume "prerelease" is always in "versions.*.flags"
                  -- we won't need to use IncludeVersionProperties.
                  --
                  -- Currently, we receive "versions.*.properties" even when this flag isn't set.
                  --
                  -- If we find a way to not receive "versions.*.properties",
                  -- we'll be able to significantly reduce response sizes.
                  flag'IncludeVersionProperties
                , flag'ExcludeNonValidated
                , targetSelect
                    target
                    flag'IncludeLatestPrereleaseAndStableVersionOnly
                    flag'IncludeLatestVersionOnly
                ]
          }

    logInfo [fmt|{START} Collecting the latest versions of extensions|]
    logInfo [fmt|{START} Collecting {pageCount} page(s) of size {pageSize}.|]

    -- We request pages of extensions from VS Code Marketplace concurrently.
    (pagesFailed, pagesFetched) <- do
      responses <- liftIO $
        AsyncPool.withTaskGroup siteConfig.nThreads $ \g -> do
          AsyncPool.mapConcurrently
            g
            ( \pageNumber -> do
                page' <-
                  -- TODO try several times
                  requestJsonEither target $
                    requestExtensionsList pageNumber
                pure (pageNumber, responseBody page')
            )
            [1 .. pageCount]

      pure $
        partitionEithersOn
          (\(k, v) -> (k,) <$> v ^? _Left)
          (\(k, v) -> (k,) <$> v ^? _Right)
          responses

    -- TODO if all fetched pages failed, we probably shouldn't proceed

    liftIO do
      writeDebugJsonCompact "pages-failed" (Aeson.encode <$> (pagesFailed & traversed . _2 %~ show))
      writeDebugJsonCompact "pages-fetched" (Aeson.encode <$> pagesFetched)

    let extensionConfigs =
          pagesFetched
            ^.. traversed . _2 . to getExtensionConfigsFromResponse . traversed

    pure extensionConfigs

getExtensionConfigsFromResponse :: Value -> [ExtensionConfig]
getExtensionConfigsFromResponse response =
  response
    ^.. filteredExtensions
      . to
        ( parseMaybe
            ( withObject [fmt|Extension|] $ \o -> do
                name :: Name <- o .: "extensionName"
                publisher :: Publisher <- o .: "publisher" >>= (.: "publisherName")
                versions_ :: [Value] <- o .: "versions"
                pure $
                  versions_
                    ^.. traversed
                      . to
                        ( parseMaybe
                            ( withObject [fmt|Version|] $ \o1 -> do
                                version :: Version <- o1 .: "version"
                                platform <-
                                  o1 .:? "targetPlatform"
                                    <&> (^. non (PlatformHumanReadable PUniversal))
                                    <&> (.platform)
                                properties :: [Value] <- o1 .: "properties"
                                let engineVersion =
                                      properties
                                        ^? traversed
                                          . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.Engine"))
                                          . key "value"
                                          . _String
                                          . _EngineVersion
                                    release =
                                      properties
                                        ^? traversed
                                          . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.PreRelease"))
                                        & is _Empty
                                    -- missingTimes = 0
                                guard (isJust engineVersion)
                                pure
                                  ExtensionConfig
                                    { engineVersion = fromJust engineVersion
                                    , name
                                    , publisher
                                    , version
                                    , platform
                                    -- , missingTimes
                                    , isRelease = IsRelease release
                                    }
                            )
                        )
                      . _Just
            )
        )
      . _Just
      . traversed

-- | Get a list of extension configs from VS Code Marketplace
getExtensionConfigsRelease :: (Settings, ?target :: Target) => [ExtensionConfig] -> [ExtensionInfo] -> MyLogger [ExtensionConfig]
getExtensionConfigsRelease extensionConfigs extensionInfoCached = do
  logInfo [fmt|{START} Identifying pre-release extensions that may have release versions|]

  let
    -- We assume that configs contain only the latest versions.
    -- Hence, if they contain a pre-release version of an extension,
    -- they don't contain a release version of the extension.

    -- We find ids of fetched pre-release configs.
    extensionIdsPreRelease =
      extensionConfigs
        ^.. traversed
          . filtered (not . coerce . (.isRelease))
          . to (\c -> (c.publisher, c.name))

    -- We find cached pre-release configs that
    -- don't have any corresponding cached release configs
    -- and get their ids.
    extensionIdsPreReleaseCached =
      let (preRelease, release) = partition (not . coerce . (.isRelease)) extensionInfoCached
          mkSet info = HashSet.fromList [(c.publisher, c.name) | c <- info]
       in HashSet.toList $
            HashSet.difference
              (mkSet preRelease)
              (mkSet release)

    extensionIdsPreReleaseAll =
      HashSet.toList $
        HashSet.fromList
          ( extensionIdsPreRelease
              <> extensionIdsPreReleaseCached
          )

  logInfo [fmt|Found {length extensionIdsPreReleaseAll} configs.|]

  liftIO do
    writeDebugJsonCompact "ids-pre-release-configs" extensionIdsPreRelease
    writeDebugJsonCompact "ids-pre-release-cached" extensionIdsPreReleaseCached

  logInfo [fmt|{FINISH} Identifying pre-release extensions that may have release versions|]

  let nRetry = ?nRetry
      siteConfig = targetSelect target ?vscodeMarketplace ?openVSX
      target = ?target

  retry_ nRetry [fmt|Collecting the release extension configs from {target}|] do
    let
      -- We need a response about a single extension.
      requestExtension publisher name =
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
                          , value = [fmt|{publisher}.{name}|]
                          }
                      , Criterion
                          { filterType = 12
                          , value = T.show flag'Unpublished
                          }
                      ]
                  , sortBy = 0
                  , sortOrder = 0
                  , pageNumber = 1
                  , pageSize = 1
                  }
              ]
          , assetTypes = []
          , flags =
              orFlags
                [ flag'IncludeVersionProperties
                , flag'ExcludeNonValidated
                ]
          }

    -- TODO We assume it's faster to fetch
    -- configs for each extension concurrently.

    -- We request configs concurrently.
    responses <- liftIO $ AsyncPool.withTaskGroup siteConfig.nThreads $ \g -> do
      AsyncPool.mapConcurrently
        g
        ( \(publisher, name) -> do
            response <- requestJsonEither target (requestExtension publisher name)
            pure ((publisher, name), responseBody response)
        )
        extensionIdsPreRelease

    let (errors, pages) =
          partitionEithersOn
            (\(k, v) -> (k,) <$> v ^? _Left)
            (\(k, v) -> (k,) <$> v ^? _Right)
            responses

    when
      (not (null errors))
      (logInfo [fmt|Could not find info about these extensions:\n\n{show $ errors}|])

    let extensionConfigsRelease =
          pages ^.. traversed . _2 . to getExtensionConfigsReleaseFromResponse . traversed

    logDebug [fmt|Release extension configs:\n\n{show $ pretty extensionConfigsRelease}|]

    pure extensionConfigsRelease

getExtensionConfigsReleaseFromResponse :: Value -> [ExtensionConfig]
getExtensionConfigsReleaseFromResponse response =
  response
    ^.. filteredExtensions
      . to
        ( parseMaybe
            ( withObject [fmt|Extension|] $ \o -> do
                name :: Name <- o .: "extensionName"
                publisher :: Publisher <- o .: "publisher" >>= (.: "publisherName")
                versions_ :: [Value] <- o .: "versions"
                let
                  -- Configs for release versions.
                  configs =
                    versions_
                      ^.. traversed
                        . to
                          ( parseMaybe
                              ( withObject [fmt|Version|] $ \o1 -> do
                                  version <- o1 .: "version"
                                  platform <-
                                    o1 .:? "targetPlatform"
                                      <&> (^. non (PlatformHumanReadable PUniversal))
                                      <&> (.platform)
                                  properties :: [Value] <- o1 .: "properties"
                                  let engineVersion =
                                        properties
                                          ^? traversed
                                            . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.Engine"))
                                            . key "value"
                                            . _String
                                            . _EngineVersion
                                      -- missingTimes = 0
                                      release =
                                        properties
                                          ^? traversed
                                            . filtered (has (key "key" . _String . only "Microsoft.VisualStudio.Code.PreRelease"))
                                          & is _Empty
                                  guard (release && isJust engineVersion)
                                  pure
                                    ExtensionConfig
                                      { engineVersion = fromJust engineVersion
                                      -- , missingTimes
                                      , name
                                      , publisher
                                      , version
                                      , platform
                                      , isRelease = IsRelease True
                                      }
                              )
                          )
                        . _Just
                  -- We need to get the most recent config for each platform.
                  -- Thus, we initialize a map `platform -> maybe config`
                  platformMap :: HashMap Platform (Maybe a)
                  platformMap = HashMap.fromList $ (enumFrom minBound) <&> (,Nothing)
                  -- We want to get configs for as many platforms as possible,
                  -- so we go through all configs.
                  --
                  -- If the map already contains a config for a platform,
                  -- we don't insert new configs for that platform
                  configsFiltered =
                    foldl'
                      ( \platformConfigs config ->
                          HashMap.insertWith
                            ( \new old ->
                                case old of
                                  Nothing -> new
                                  x -> x
                            )
                            config.platform
                            (Just config)
                            platformConfigs
                      )
                      platformMap
                      configs
                  -- It may happen that there's no config for a platform.
                  -- Therefore, we filter out the non-existing configs from the map values.
                  configsFiltered' = configsFiltered ^.. traversed . _Just
                pure configsFiltered'
            )
        )
      . _Just
      . traversed

-- | Run a config fetcher depending on the target site
-- to (hopefully) get the extension configs
runConfigFetcher :: (TargetSettings) => [ExtensionInfo] -> MyLogger [ExtensionConfig]
runConfigFetcher extensionInfoCached = do
  let
    target = ?target
    message :: Text
    message = [fmt|Collecting the latest pre-release and release extension configs from {target}.|]

  logInfo [fmt|{START} {message}|]

  extensionConfigsLatest <- getExtensionConfigs

  extensionConfigsRelease <-
    targetSelect
      target
      -- For VS Code, latest configs already include
      -- both release and pre-release versions
      (pure [])
      (getExtensionConfigsRelease extensionConfigsLatest extensionInfoCached)

  -- TODO check
  -- These configs should be unique because we found fetched configs
  -- for pre-release configs that didn't have any corresponding release configs.
  let extensionConfigs = extensionConfigsLatest <> extensionConfigsRelease

  logInfo [fmt|{FINISH} {message}|]

  -- finally, we return the configs
  pure extensionConfigs

mkTargetJson :: Target -> FilePath -> FilePath -> FilePath
mkTargetJson target prefix suffix = [fmt|{prefix}/{showTarget target}-{suffix}.json|]

decodeFile :: (Aeson.FromJSON a) => FilePath -> BS.ByteString -> MyLogger [a]
decodeFile path initialContent = do
  existsInfoCacheFile <- liftIO $ Directory.doesFileExist path

  when (not existsInfoCacheFile) do
    logError [fmt|{FAIL} The file at `{path}` doesn't exist.|]

    logInfo [fmt|{START} Creating a file at `{path}`.|]

    liftIO $ BS.writeFile path initialContent

    logInfo [fmt|{FINISH} Creating a file at `{path}`.|]

  -- TODO support yaml
  extensionInfoCached <- tryAny $ liftIO $ Aeson.eitherDecodeFileStrict path

  let handleError errorMessage = do
        logError [fmt|{FAIL} Decoding the file at {path}:\n\n{errorMessage}|]
        pure []

  case extensionInfoCached of
    Left err -> handleError (show err)
    Right (Left err) -> handleError err
    Right (Right v) -> pure v

processTarget :: (TargetSettings) => MyLogger ()
processTarget =
  do
    let
      mkTargetLatestJson :: String -> FilePath
      mkTargetLatestJson prefix = mkTargetJson ?target prefix "latest"

    let
      ?extensionInfoCachePath = mkTargetLatestJson ?cacheDir
      ?mkTargetLatestJson = mkTargetLatestJson

    extensionInfoCached <- decodeFile ?extensionInfoCachePath "[ ]"

    -- We first run a crawler to get the extension configs.
    extensionConfigs <-
      runConfigFetcher extensionInfoCached
        `logAndForwardError` "when running crawler"

    -- Then, we run a fetcher to get hashes.
    runInfoFetcher extensionInfoCached extensionConfigs
      `logAndForwardError` "when running fetcher for latest extensions"
    -- in case of errors, rethrow an exception
    `logAndForwardError` (let target = ?target in [fmt|when requesting {target}|])

newtype ConfigOptions w = ConfigOptions
  { config :: w ::: Maybe FilePath <?> "Path to a config file"
  }
  deriving stock (Generic)

instance ParseRecord (ConfigOptions Wrapped)
deriving anyclass instance ParseRecord (ConfigOptions Unwrapped)

main :: IO ()
main =
  -- An asynchronous exception is one that was thrown to this thread from another thread.
  -- In a handler like try, an asynchronous appears like any other exception.
  --
  -- TODO Consider catching asynchronous exceptions coming from outside the program separately.
  -- https://neilmitchell.blogspot.com/2015/05/handling-control-c-in-haskell.html

  withUtf8 do
    configOptions :: (ConfigOptions Unwrapped) <- unwrapRecord "Updater"
    -- we'll let logs be written to stdout as soon as they come
    hSetBuffering stdout NoBuffering
    config_ <-
      case configOptions.config of
        Nothing -> do
          putStrLn [fmt|No path to config file specified. Using the default config.|]
          pure (mkDefaultAppConfig def)
        Just s -> do
          -- TODO use decodeFile
          appConfig <- tryAny $ decodeFileThrow s
          case appConfig of
            Left err -> error [fmt|Could not decode the config file. Aborting because got an error:\n\n{show err}|]
            Right appConfig_ -> pure $ mkDefaultAppConfig appConfig_

    let dataDir = config_.dataDir
        cacheDir = [fmt|{dataDir}/cache|]
        debugDir = [fmt|{dataDir}/debug|]
        tmpDir = [fmt|{dataDir}/tmp|]
        fetchedDir = [fmt|{tmpDir}/fetched|]
        failedDir = [fmt|{tmpDir}/failed|]

    forM_
      [dataDir, fetchedDir, failedDir, cacheDir, debugDir]
      (liftIO . Directory.createDirectoryIfMissing True)

    let ?dataDir = dataDir
        ?cacheDir = cacheDir
        ?debugDir = debugDir
        ?failedDir = failedDir
        ?fetchedDir = fetchedDir
        ?tmpDir = tmpDir
        ?programTimeout = config_.programTimeout
        ?retryDelay = config_.retryDelay
        ?queueCapacity = config_.queueCapacity
        ?nRetry = config_.nRetry
        ?collectGarbage = config_.collectGarbage
        ?garbageCollectorDelay = config_.garbageCollectorDelay
        ?openVSX = config_.openVSX
        ?processedLoggerDelay = config_.processedLoggerDelay
        ?vscodeMarketplace = config_.vscodeMarketplace
        -- ?maxMissingTimes = config_.maxMissingTimes
        ?requestResponseTimeout = config_.requestResponseTimeout

    let timeoutMicroseconds = fromIntegral config_.programTimeout * _MICROSECONDS

    -- We have to use `timeout` from unbounded-delays
    -- because the timeout can be more than 36 minutes
    -- https://hackage-content.haskell.org/package/base-4.18.1.0/docs/System-Timeout.html#v:timeout
    void $ timeout timeoutMicroseconds do
      withBackgroundLogger @IO
        defCapacity
        ( cfilter (\(Msg sev _ _) -> sev >= config_.logSeverity) $
            formatWith fmtMessage logTextStdout
        )
        (pure ())
        $ \logger -> usingLoggerT logger do
          logInfo [fmt|{START} Updating extensions|]
          logInfo [fmt|{START} Config:\n{encodePretty defConfig config_}|]

          forM_ ([VSCodeMarketplace | ?vscodeMarketplace.enable] <> [OpenVSX | ?openVSX.enable]) $
            \target ->
              _myLoggerT do
                ( retry_
                    ?nRetry
                    [fmt|Processing {target}|]
                    ( do
                        let ?target = target
                            ?threadNumber = targetSelect target ?vscodeMarketplace.nThreads ?openVSX.nThreads
                        processTarget
                    )
                  )
                  `logAndForwardError` [fmt|when processing {target}|]
          logInfo [fmt|{FINISH} Updating extensions|]
