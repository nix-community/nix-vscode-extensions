{-# LANGUAGE DeriveAnyClass #-}

module Extensions where

import Control.Lens (Prism', has, prism', review, (#), (^?), _Just)
import Control.Monad (guard, void)
import Data.Aeson (FromJSON (..), Options (unwrapUnaryRecords), ToJSON (toJSON), Value (..), defaultOptions, genericParseJSON, genericToJSON, withText)
import Data.Aeson.Lens (_String)
import Data.Aeson.Types (parseFail)
import Data.Generics.Labels ()
import Data.Hashable (Hashable)
import Data.Maybe (fromJust)
import Data.String (IsString)
import Data.String.Interpolate (i)
import Data.Text (Text, unpack)
import Data.Text qualified as Text
import Data.Time (UTCTime)
import Data.Void (Void)
import GHC.Generics (Generic)
import Text.Megaparsec (Parsec, choice, skipMany, (<|>))
import Text.Megaparsec qualified as TM (parseMaybe)
import Text.Megaparsec.Char (asciiChar, string)
import Text.Megaparsec.Char.Lexer (decimal)

-- | Possible targets
data Target = VSCodeMarketplace | OpenVSX deriving (Eq)

-- | Select an action depending on a target
targetSelect :: Target -> p -> p -> p
targetSelect target f g =
  case target of
    VSCodeMarketplace -> f
    OpenVSX -> g

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

data VersionModifier = Veq | Vgeq deriving (Ord, Eq, Generic, Hashable)

data EngineVersion = EngineVersion {_modifier :: VersionModifier, _majorVersion, _minorVersion, _patchVersion :: Int}
  deriving (Eq, Ord, Hashable, Generic)

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

instance Show VersionModifier where
  show = unpack . (_VersionModifier #)

instance Show EngineVersion where
  show = unpack . (_EngineVersion #)

-- | Examples of versions for VSCode engine used in extensions
versions :: [Text]
versions =
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

-- | Parsed versions
--
-- >>> versionsParsed
-- [Just ^0.0.0,Just ^0.10.0,Just ^1.27.0,Just ^0.10.0,Just ^0.10.0,Just ^0.9.0,Just 0.1.0,Just 1.57.0,Just 1.0.0,Just ^0.0.0]
versionsParsed :: [Maybe EngineVersion]
versionsParsed = TM.parseMaybe parseVersion' <$> versions

type Parser = Parsec Void Text

-- | Parse 'EngineVersion'
parseVersion' :: Parser EngineVersion
parseVersion' =
  (string "*" >> pure defaultEngineVersion)
    <|> do
      _modifier <-
        choice
          [ Vgeq <$ (string "^" <|> string ">=")
          , Veq <$ string ""
          ]
      _majorVersion <- decimal <|> (0 <$ string "x")
      void $ string "."
      _minorVersion <- decimal <|> (0 <$ string "x")
      void $ string "."
      _patchVersion <- decimal <|> (0 <$ string "x")
      skipMany asciiChar
      pure EngineVersion{..}

_EngineVersion :: Prism' Text EngineVersion
_EngineVersion = prism' embed_ match_
 where
  embed_ EngineVersion{..} = [i|#{review _VersionModifier _modifier}#{_majorVersion}.#{_minorVersion}.#{_patchVersion}|]
  match_ = TM.parseMaybe parseVersion'

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

instance FromJSON EngineVersion where
  parseJSON = withText "Engine version" $ \t -> do
    let t' = t ^? _EngineVersion
    guard (has _Just t')
    pure (fromJust t')

instance ToJSON EngineVersion where
  toJSON = (_String #) . (_EngineVersion #)

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
  deriving (Generic, FromJSON, ToJSON, Show, Eq, Hashable)

defaultEngineVersion :: EngineVersion
defaultEngineVersion = EngineVersion{_modifier = Vgeq, _majorVersion = 0, _minorVersion = 0, _patchVersion = 0}

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
  deriving (Generic, FromJSON, ToJSON, Show)
