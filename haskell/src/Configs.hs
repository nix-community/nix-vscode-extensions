{-# LANGUAGE DeriveAnyClass #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Configs where

import Colog
import Control.Lens
import Data.Aeson (FromJSON (parseJSON), ToJSON, Value (String), withArray, withText)
import Data.Aeson.Key (toText)
import Data.Aeson.Lens (members, _String)
import Data.Aeson.Types (Parser, typeMismatch)
import Data.Default (Default (..))
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.Yaml (decodeFileEither, parseMaybe)
import Data.Yaml.Pretty (defConfig, encodePretty)
import Extensions
import GHC.Generics (Generic)

type family HKD f a where
  HKD Identity a = a
  HKD f a = f a

data ReleaseExtension = ReleaseExtension {publisher :: Publisher, name :: Name}
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON)

newtype ReleaseExtensions = ReleaseExtensions {releaseExtensions :: [ReleaseExtension]}
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON)

data SiteConfig f = SiteConfig
  { pageSize :: HKD f Int
  -- ^ Number of extensions per page in a request
  , pageCount :: HKD f Int
  -- ^ Number of extension pages to request
  , nThreads :: HKD f Int
  -- ^ Number of threads to use for fetching
  , release :: HKD f ReleaseExtensions
  -- ^ Extensions that require the release version
  , enable :: HKD f Bool
  }
  deriving stock (Generic)

data AppConfig f = AppConfig
  { runN :: HKD f Int
  -- ^ Times to process a target site
  , processedLoggerDelay :: HKD f Int
  -- ^ Period in seconds till the next logging about processed extensions
  , garbageCollectorDelay :: HKD f Int
  -- ^ Period in seconds till the next garbage collection
  , collectGarbage :: HKD f Bool
  -- ^ Whether to collect garbage in /nix/store
  , programTimeout :: HKD f Int
  -- ^ Total time a program may run
  , retryDelay :: HKD f Int
  -- ^ Seconds to wait before retrying
  , nRetry :: HKD f Int
  -- ^ Number of times to retry an action
  , logSeverity :: HKD f Severity
  -- ^ Log severity level
  , dataDir :: HKD f FilePath
  -- ^ Data directory
  , queueCapacity :: HKD f Int
  -- ^ Max number of elements to store in a queue
  , maxMissingTimes :: HKD f Int
  -- ^ Max number of times an extension may be missing before it's removed from cache
  , requestResponseTimeout :: HKD f Int
  -- ^ Seconds to wait until the site responds
  , openVSX :: HKD f (SiteConfig f)
  -- ^ Config for Open VSX
  , vscodeMarketplace :: HKD f (SiteConfig f)
  -- ^ Config for VSCode Marketplace
  }
  deriving stock (Generic)

deriving instance Generic Severity

instance ToJSON (SiteConfig Identity)

instance ToJSON Severity

instance ToJSON (AppConfig Identity)

instance Default (SiteConfig Maybe)

type AppConfig' = (?config :: AppConfig Identity)

data ProcessTargetConfig a = ProcessTargetConfig
  { target :: Target
  , nThreads :: Int
  , queueCapacity :: Int
  , dataDir :: FilePath
  , logger :: LogAction a Message
  }

-- | Config for a crawler
data CrawlerConfig a = CrawlerConfig
  { target :: Target
  , nRetry :: Int
  , logger :: LogAction a Message
  }

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

instance FromJSON (SiteConfig Identity)
instance FromJSON (SiteConfig Maybe)
deriving instance Eq (SiteConfig Maybe)

instance FromJSON ReleaseExtensions where
  parseJSON obj =
    pure $
      ReleaseExtensions $
        (obj ^@.. members)
          ^.. traversed
            . to
              ( \(k, v) ->
                  let publisher = Publisher (toText k)
                   in parseMaybe
                        ( withArray "Names" $ \a ->
                            pure $ a ^.. traversed . _String . to (\name -> ReleaseExtension{name = Name name, ..})
                        )
                        v
              )
            . _Just
            . traversed

instance FromJSON Severity where
  parseJSON :: Value -> Data.Aeson.Types.Parser Severity
  parseJSON = withText
    "Severity"
    \case
      "Debug" -> pure Debug
      "Info" -> pure Info
      "Warning" -> pure Warning
      "Error" -> pure Error
      p -> typeMismatch "Severity" (String p)

instance FromJSON (AppConfig Identity)
instance FromJSON (AppConfig Maybe)

instance Default (AppConfig Maybe)

_MICROSECONDS :: Int
_MICROSECONDS = 1_000_000

defaultOpenVSXConfig :: SiteConfig Identity
defaultOpenVSXConfig =
  SiteConfig
    { pageSize = 1_000
    , pageCount = 10
    , nThreads = 30
    , release = ReleaseExtensions []
    , enable = True
    }

defaultVSCodeMarketplaceConfig :: SiteConfig Identity
defaultVSCodeMarketplaceConfig =
  SiteConfig
    { pageSize = 1_000
    , pageCount = 100
    , nThreads = 100
    , release = ReleaseExtensions []
    , enable = True
    }

mkDefaultConfig :: SiteConfig Identity -> SiteConfig Maybe -> SiteConfig Identity
mkDefaultConfig config SiteConfig{..} =
  SiteConfig
    { pageSize = pageSize ^. non config.pageSize
    , pageCount = pageCount ^. non config.pageCount
    , nThreads = nThreads ^. non config.nThreads
    , release = release ^. non config.release
    , enable = enable ^. non config.enable
    }

mkDefaultAppConfig :: AppConfig Maybe -> AppConfig Identity
mkDefaultAppConfig AppConfig{..} =
  AppConfig
    { runN = runN ^. non 1
    , processedLoggerDelay = processedLoggerDelay ^. non 2
    , garbageCollectorDelay = garbageCollectorDelay ^. non 30
    , collectGarbage = collectGarbage ^. non False
    , programTimeout = programTimeout ^. non 900
    , retryDelay = retryDelay ^. non 20
    , nRetry = nRetry ^. non 3
    , logSeverity = logSeverity ^. non Info
    , dataDir = dataDir ^. non "data"
    , queueCapacity = queueCapacity ^. non 200
    , maxMissingTimes = maxMissingTimes ^. non 5
    , requestResponseTimeout = requestResponseTimeout ^. non 100
    , openVSX = openVSX ^. non def . to (mkDefaultConfig defaultOpenVSXConfig)
    , vscodeMarketplace = vscodeMarketplace ^. non def . to (mkDefaultConfig defaultVSCodeMarketplaceConfig)
    }

-- | A type for printing multiline stuff when using HLS
newtype Pretty = Pretty String

instance Show Pretty where
  show :: Pretty -> String
  show (Pretty s) = s

-- >>> prettyConfig
-- collectGarbage: false
-- dataDir: data
-- garbageCollectorDelay: 30
-- logSeverity: Info
-- maxMissingTimes: 5
-- nRetry: 3
-- openVSX:
--   enable: true
--   nThreads: 30
--   pageCount: 10
--   pageSize: 1000
--   release:
--     releaseExtensions:
--     - name: gitlens
--       publisher: eamodio
--     - name: rust-analyzer
--       publisher: rust-lang
--     - name: rewrap
--       publisher: stkb
-- processedLoggerDelay: 2
-- programTimeout: 900
-- queueCapacity: 200
-- requestResponseTimeout: 100
-- retryDelay: 20
-- runN: 1
-- vscodeMarketplace:
--   enable: true
--   nThreads: 100
--   pageCount: 100
--   pageSize: 1000
--   release:
--     releaseExtensions:
--     - name: gitlens
--       publisher: eamodio
--     - name: rust-analyzer
--       publisher: rust-lang
--     - name: rewrap
--       publisher: stkb
prettyConfig :: IO Pretty
prettyConfig = Pretty . either show (T.unpack . decodeUtf8 . encodePretty defConfig . mkDefaultAppConfig) <$> decodeFileEither @(AppConfig Maybe) "config.yaml"
