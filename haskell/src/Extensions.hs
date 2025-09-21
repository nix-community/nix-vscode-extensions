{-# LANGUAGE DeriveAnyClass #-}

module Extensions where

import Control.Lens
import Control.Monad (guard)
import Data.Aeson (FromJSON (..), Options (unwrapUnaryRecords), ToJSON (toJSON), Value (..), defaultOptions, genericParseJSON, genericToJSON, withText)
import Data.Aeson.Lens (_String)
import Data.Aeson.Types (parseFail)
import Data.Aeson.Types qualified
import Data.Functor (void)
import Data.Generics.Labels ()
import Data.Hashable (Hashable)
import Data.Maybe (fromJust, fromMaybe)
import Data.String (IsString)
import Data.String.Interpolate (i)
import Data.Text (Text, unpack)
import Data.Text qualified as T
import Data.Text qualified as Text
import Data.Time (UTCTime)
import Data.Versions (SemVer (..), prettySemVer, semver')
import Data.Void (Void)
import GHC.Generics (Generic)
import Text.Megaparsec (Parsec, choice, many, (<|>))
import Text.Megaparsec qualified as TM (parse, parseMaybe)
import Text.Megaparsec.Char (asciiChar, string)
import Text.Megaparsec.Char.Lexer (decimal)

-- | Possible targets
data Target = VSCodeMarketplace | OpenVSX
  deriving stock (Eq)

data Flags
  = Flags'Validated
  | Flags'Public
  | Flags'Preview
  | Flags'Verified
  | Flags'Trial
  deriving stock (Enum, Bounded)

newtype Name = Name {_name :: Text}
  deriving newtype (IsString, Eq, Ord, Hashable)
  deriving stock (Generic)

newtype Publisher = Publisher {_publisher :: Text}
  deriving newtype (IsString, Eq, Ord, Hashable)
  deriving stock (Generic)

-- TODO remove since it's unused
newtype LastUpdated = LastUpdated {_lastUpdated :: UTCTime}
  deriving newtype (Eq, Ord, Hashable, Show)
  deriving stock (Generic)

newtype Version = Version {_version :: SemVer}
  deriving newtype (Eq, Ord, Hashable)
  deriving stock (Generic)

data VersionModifier = Veq | Vgeq
  deriving stock (Ord, Eq, Generic)
  deriving anyclass (Hashable)

data EngineVersion = EngineVersion
  { _modifier :: VersionModifier
  , _version :: SemVer
  }
  deriving stock (Eq, Ord, Generic)
  deriving anyclass (Hashable)

-- platform of an extension
data Platform
  = -- | universal extensions should have the lowest order
    PUniversal
  | PLinux_x64
  | PLinux_arm64
  | PDarwin_x64
  | PDarwin_arm64
  deriving stock (Generic, Eq, Ord, Enum, Bounded)
  deriving anyclass (Hashable)

-- | A simple config that is enough to fetch an extension
data ExtensionConfig = ExtensionConfig
  { name :: Name
  , publisher :: Publisher
  , lastUpdated :: LastUpdated
  , version :: Version
  , platform :: Platform
  , missingTimes :: Int
  , engineVersion :: EngineVersion
  }
  deriving stock (Generic, Show, Eq)
  deriving anyclass (FromJSON, ToJSON, Hashable)

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
  , engineVersion :: EngineVersion
  -- ^ engine version that's required to run this extension
  --
  -- See [Visual Studio Code compatibility](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#visual-studio-code-compatibility)
  }
  deriving stock (Generic, Show)
  deriving anyclass (FromJSON, ToJSON)

_Flags :: Prism' Text Flags
_Flags = prism' embed_ match_
 where
  embed_ = \case
    Flags'Validated -> "validated"
    Flags'Public -> "public"
    Flags'Preview -> "preview"
    Flags'Verified -> "verified"
    Flags'Trial -> "trial"
  match_ :: Text -> Maybe Flags
  match_ x
    | x == embed_ Flags'Validated = Just Flags'Validated
    | x == embed_ Flags'Public = Just Flags'Public
    | x == embed_ Flags'Preview = Just Flags'Preview
    | x == embed_ Flags'Verified = Just Flags'Verified
    | x == embed_ Flags'Trial = Just Flags'Trial
    | otherwise = Nothing

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

_VersionModifier :: Prism' Text VersionModifier
_VersionModifier = prism' embed_ match_
 where
  embed_ = \case
    Veq -> ""
    Vgeq -> "^"
  match_ x
    | x == embed_ Veq = Just Veq
    | x == embed_ Vgeq = Just Vgeq
    | x == ">=" = Just Vgeq
    | otherwise = Nothing

_EngineVersion :: Prism' Text EngineVersion
_EngineVersion = prism' embed_ match_
 where
  -- TODO use OverloadedRecordDot
  embed_ EngineVersion{_version, _modifier} =
    [i|#{review _VersionModifier _modifier}#{prettySemVer _version}|]
  match_ = TM.parseMaybe parseEngineVersion

type Parser = Parsec Void Text

-- | Parse a SemVer-like 'Version'.
--
-- Allow leading zeros.
--
-- >>> TM.parseMaybe parseVersion <$> versions
parseVersion :: Parser Version
parseVersion = do
  _svMajor <- decimal
  void $ string "."
  _svMinor <- decimal
  void $ string "."
  _svPatch <- decimal
  rest <- many asciiChar
  let semVer =
        SemVer
          { _svPreRel = Nothing
          , _svMeta = Nothing
          , _svMajor
          , _svMinor
          , _svPatch
          }
  pure $ Version $ fromMaybe semVer (TM.parseMaybe semver' (prettySemVer semVer <> T.pack rest))

versions :: [Text]
versions =
  [ "2022.09.290700"
  , "23.3.0-canary-open-0313-1900"
  , "1.0.0-beta.1"
  , "1.13.1712347770"
  , "0.1.8+vizcar"
  ]

-- | Parse 'EngineVersion'
--
-- >>> TM.parseMaybe parseEngineVersion <$> engineVersions
-- [Just ^0.0.0,Just ^0.10.0,Just ^1.27.0-insider,Just ^0.10.0,Just ^0.10.0,Just ^0.9.0-pre.1,Just 0.1.0,Just 1.57.0-insider,Just 1.0.0,Just ^0.0.0]
parseEngineVersion :: Parser EngineVersion
parseEngineVersion =
  (string "*" >> pure defaultEngineVersion)
    <|> do
      _modifier <-
        choice
          [ Vgeq <$ (string "^" <|> string ">=")
          , Veq <$ string ""
          ]
      _svMajor <- decimal <|> (0 <$ string "x")
      void $ string "."
      _svMinor <- decimal <|> (0 <$ string "x")
      void $ string "."
      _svPatch <- decimal <|> (0 <$ string "x")
      rest <- many asciiChar
      let semVer =
            SemVer
              { _svPreRel = Nothing
              , _svMeta = Nothing
              , _svMajor
              , _svMinor
              , _svPatch
              }
      pure
        EngineVersion
          { _version =
              fromMaybe
                semVer
                ( TM.parseMaybe
                    semver'
                    (prettySemVer semVer <> T.pack rest)
                )
          , _modifier
          }

-- | Examples of versions for VSCode engine used in extensions
engineVersions :: [Text]
engineVersions =
  [ "^0.0.0"
  , "^0.10.x"
  , "^1.27.0-insider"
  , ">=0.10.0"
  , ">=0.10.x"
  , ">=0.9.0-pre.1"
  , "0.1.x"
  , "1.57.0-insider"
  , "1.x.x"
  , "*"
  ]

defaultEngineVersion :: EngineVersion
defaultEngineVersion =
  EngineVersion
    { _modifier = Vgeq
    , _version =
        SemVer
          { _svMajor = 0
          , _svMinor = 0
          , _svPatch = 0
          , _svPreRel = Nothing
          , _svMeta = Nothing
          }
    }

extFlagsAllowed :: [Text]
extFlagsAllowed = enumFrom minBound ^.. traversed . to (_Flags #)

-- | Select an action depending on a target
targetSelect :: Target -> p -> p -> p
targetSelect target f g =
  case target of
    VSCodeMarketplace -> f
    OpenVSX -> g

-- | Possible action statuses
ppTarget :: Target -> Text
ppTarget x = targetSelect x "VSCode Marketplace" "Open VSX"

instance Show Target where
  show :: Target -> String
  show = T.unpack . ppTarget

instance Show Flags where
  show :: Flags -> String
  show = Text.unpack . (_Flags #)

instance Show Version where
  show :: Version -> String
  show v = T.unpack $ prettySemVer v._version

instance FromJSON Version where
  parseJSON :: Value -> Data.Aeson.Types.Parser Version
  parseJSON = withText "SemVer" $ either (parseFail . show) pure . TM.parse parseVersion "SemVer"

instance ToJSON Version where
  toJSON :: Version -> Value
  toJSON v = String $ prettySemVer v._version

instance FromJSON Platform where
  parseJSON :: Value -> Data.Aeson.Types.Parser Platform
  parseJSON (String s) =
    case s ^? _Platform of
      Just s' -> pure s'
      Nothing -> parseFail "Could not parse platform"
  parseJSON _ = parseFail "Expected a string"

instance ToJSON Platform where
  toJSON :: Platform -> Value
  toJSON = String . review _Platform

instance Show Platform where
  show :: Platform -> String
  show = unpack . review _Platform

instance Show VersionModifier where
  show = unpack . (_VersionModifier #)

instance Show EngineVersion where
  show = unpack . (_EngineVersion #)

instance FromJSON EngineVersion where
  parseJSON :: Value -> Data.Aeson.Types.Parser EngineVersion
  parseJSON = withText "Engine version" $ \engineVersion -> do
    let t' = engineVersion ^? _EngineVersion
    guard (has _Just t')
    pure (fromJust t')

instance ToJSON EngineVersion where
  toJSON :: EngineVersion -> Value
  toJSON = (_String #) . (_EngineVersion #)

aesonOptions :: Options
aesonOptions = defaultOptions{unwrapUnaryRecords = True}

instance Show Name where
  show = Text.unpack . _name
instance FromJSON Name where
  parseJSON = genericParseJSON aesonOptions
instance ToJSON Name where
  toJSON = genericToJSON aesonOptions

instance Show Publisher where
  show = Text.unpack . _publisher
instance FromJSON Publisher where
  parseJSON = genericParseJSON aesonOptions
instance ToJSON Publisher where
  toJSON = genericToJSON aesonOptions

instance FromJSON LastUpdated where
  parseJSON = genericParseJSON aesonOptions
instance ToJSON LastUpdated where
  toJSON = genericToJSON aesonOptions
