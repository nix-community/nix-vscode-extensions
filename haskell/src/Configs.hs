{-# LANGUAGE DeriveAnyClass #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Configs where

import Colog
import Control.Lens
import Data.Aeson (FromJSON (parseJSON), ToJSON, Value (String), withText)
import Data.Aeson.Types (Parser, typeMismatch)
import Data.Default (Default (..))
import Data.Text qualified as T
import Data.Text.Encoding (decodeUtf8)
import Data.Yaml (decodeFileEither)
import Data.Yaml.Pretty (defConfig, encodePretty)
import Extensions
import GHC.Generics (Generic)

type family HKD f a where
  HKD Identity a = a
  HKD f a = f a

data ReleaseExtension = ReleaseExtension {publisher :: Publisher, name :: Name}
  deriving stock (Eq, Show, Generic)
  deriving anyclass (ToJSON)

data SiteConfig f = SiteConfig
  { pageSize :: HKD f Int
  -- ^ Number of extensions per page in a request
  , pageCount :: HKD f Int
  -- ^ Number of extension pages to request
  , nThreads :: HKD f Int
  -- ^ Number of threads to use for fetching
  , enable :: HKD f Bool
  -- ^ Whether to enable functionality for this site
  }
  deriving stock (Generic)

-- | Application configuration.
--
-- We use HKD because we need to allow optional fields when parsing
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

type TargetSettings =
  ( ?target :: Target
  , ?threadNumber :: Int
  , Settings
  )

-- | Settings that don't change.
--
-- @target@ was included because it's ubiquitous.
type Settings =
  ( ?queueCapacity :: Int
  , ?dataDir :: FilePath
  , ?debugDir :: FilePath
  , ?cacheDir :: FilePath
  , ?nRetry :: Int
  , ?tmpDir :: FilePath
  , ?maxMissingTimes :: Int
  , ?collectGarbage :: Bool
  , ?processedLoggerDelay :: Int
  , ?garbageCollectorDelay :: Int
  , ?requestResponseTimeout :: Int
  , ?openVSX :: SiteConfig Identity
  , ?vscodeMarketplace :: SiteConfig Identity
  , ?retryDelay :: Int
  , ?programTimeout :: Int
  )

instance FromJSON (SiteConfig Identity)
instance FromJSON (SiteConfig Maybe)
deriving instance Eq (SiteConfig Maybe)


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

_MICROSECONDS :: Integer
_MICROSECONDS = 1_000_000

defaultOpenVSXConfig :: SiteConfig Identity
defaultOpenVSXConfig =
  SiteConfig
    { pageSize = 1_000
    , pageCount = 10
    , nThreads = 30
    , enable = True
    }

defaultVSCodeMarketplaceConfig :: SiteConfig Identity
defaultVSCodeMarketplaceConfig =
  SiteConfig
    { pageSize = 1_000
    , pageCount = 100
    , nThreads = 100
    , enable = True
    }

mkDefaultConfig :: SiteConfig Identity -> SiteConfig Maybe -> SiteConfig Identity
mkDefaultConfig config sc =
  SiteConfig
    { pageSize = sc.pageSize ^. non config.pageSize
    , pageCount = sc.pageCount ^. non config.pageCount
    , nThreads = sc.nThreads ^. non config.nThreads
    , enable = sc.enable ^. non config.enable
    }

mkDefaultAppConfig :: AppConfig Maybe -> AppConfig Identity
mkDefaultAppConfig ac =
  AppConfig
    { runN = ac.runN ^. non 1
    , processedLoggerDelay = ac.processedLoggerDelay ^. non 2
    , garbageCollectorDelay = ac.garbageCollectorDelay ^. non 30
    , collectGarbage = ac.collectGarbage ^. non False
    , programTimeout = ac.programTimeout ^. non 900
    , retryDelay = ac.retryDelay ^. non 20
    , nRetry = ac.nRetry ^. non 3
    , logSeverity = ac.logSeverity ^. non Info
    , dataDir = ac.dataDir ^. non "data"
    , queueCapacity = ac.queueCapacity ^. non 200
    , maxMissingTimes = ac.maxMissingTimes ^. non 5
    , requestResponseTimeout = ac.requestResponseTimeout ^. non 100
    , openVSX = ac.openVSX ^. non def . to (mkDefaultConfig defaultOpenVSXConfig)
    , vscodeMarketplace = ac.vscodeMarketplace ^. non def . to (mkDefaultConfig defaultVSCodeMarketplaceConfig)
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
prettyConfig :: IO Pretty
prettyConfig = Pretty . either show (T.unpack . decodeUtf8 . encodePretty defConfig . mkDefaultAppConfig) <$> decodeFileEither @(AppConfig Maybe) "config.yaml"
