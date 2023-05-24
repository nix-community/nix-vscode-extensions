module Configs where

import Colog
import Control.Lens
import Data.Aeson (FromJSON (parseJSON), Value (String), decodeFileStrict, withArray, withText)
import Data.Aeson.Key (toText)
import Data.Aeson.Lens (members, _String)
import Data.Aeson.Types (parseMaybe, typeMismatch)
import Extensions
import GHC.Generics (Generic)

_CONFIG_ENV_VAR :: String
_CONFIG_ENV_VAR = "CONFIG"

type family HKD f a where
  HKD Identity a = a
  HKD f a = f a

data SiteConfig f = SiteConfig
  { pageSize :: HKD f Int
  -- ^ Number of extensions per page in a request
  , pageCount :: HKD f Int
  -- ^ Number of extension pages to request
  , nThreads :: HKD f Int
  -- ^ Number of threads to use for fetching
  , release :: HKD f ReleaseExtensions
  -- ^ Extensions that require the release version
  }
  deriving (Generic)

newtype ReleaseExtensions = ReleaseExtensions {_releaseExtensions :: [ReleaseExtension]} deriving (Eq, Show)

data ReleaseExtension = ReleaseExtension {_publisher :: Publisher, _name :: Name} deriving (Eq, Show)

data AppConfig f = AppConfig
  { runN :: HKD f Int
  -- ^ Times to process a target site
  , processedLoggerDelay :: HKD f Int
  -- ^ Seconds to wait for a logger of info about processed extensions until logging again
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
  deriving (Generic)

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
                  let _publisher = Publisher (toText k)
                   in parseMaybe
                        ( withArray "Names" $ \a ->
                            pure $ a ^.. traversed . _String . to (\name -> ReleaseExtension{_name = Name name, ..})
                        )
                        v
              )
            . _Just
            . traversed

instance FromJSON Severity where
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

_MICROSECONDS :: Int
_MICROSECONDS = 1_000_000

defaultSiteConfig :: SiteConfig Maybe
defaultSiteConfig =
  SiteConfig
    { pageSize = Nothing
    , pageCount = Nothing
    , nThreads = Nothing
    , release = Nothing
    }

defaultOpenVSXConfig :: SiteConfig Identity
defaultOpenVSXConfig =
  SiteConfig
    { pageSize = 1_000
    , pageCount = 5
    , nThreads = 100
    , release = ReleaseExtensions []
    }

defaultVSCodeMarketplaceConfig :: SiteConfig Identity
defaultVSCodeMarketplaceConfig =
  SiteConfig
    { pageSize = 1_000
    , pageCount = 70
    , nThreads = 100
    , release = ReleaseExtensions []
    }

mkDefaultConfig :: SiteConfig Identity -> SiteConfig Maybe -> SiteConfig Identity
mkDefaultConfig config SiteConfig{..} =
  SiteConfig
    { pageSize = pageSize ^. non config.pageSize
    , pageCount = pageCount ^. non config.pageCount
    , nThreads = nThreads ^. non config.nThreads
    , release = release ^. non config.release
    }

mkDefaultAppConfig :: AppConfig Maybe -> AppConfig Identity
mkDefaultAppConfig AppConfig{..} =
  AppConfig
    { runN = runN ^. non 1
    , processedLoggerDelay = (processedLoggerDelay ^. non 2) * _MICROSECONDS
    , retryDelay = (retryDelay ^. non 2) * _MICROSECONDS
    , nRetry = nRetry ^. non 3
    , logSeverity = logSeverity ^. non Info
    , dataDir = dataDir ^. non "data"
    , queueCapacity = queueCapacity ^. non 200
    , maxMissingTimes = maxMissingTimes ^. non 5
    , requestResponseTimeout = requestResponseTimeout ^. non 100
    , openVSX = openVSX ^. non defaultSiteConfig . to (mkDefaultConfig defaultOpenVSXConfig)
    , vscodeMarketplace = vscodeMarketplace ^. non defaultSiteConfig . to (mkDefaultConfig defaultVSCodeMarketplaceConfig)
    }

checkReadConfig :: IO String
checkReadConfig = do
  f :: Maybe (AppConfig Maybe) <- decodeFileStrict "config.json"
  case f of
    Nothing -> pure "bad"
    Just (mkDefaultAppConfig -> a) -> pure $ show a.vscodeMarketplace.release

-- >>> checkReadConfig
-- "ReleaseExtensions [ReleaseExtension {publisher = eamodio, name = gitlens}]"
