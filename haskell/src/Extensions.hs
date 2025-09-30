{-# LANGUAGE DeriveAnyClass #-}

module Extensions where

import Control.Lens (Prism', has, prism', review, traversed, (#), (%~), (^..), (^?), _1, _Just)
import Control.Lens qualified as Lens
import Control.Monad (guard)
import Data.Aeson (FromJSON (..), Options (..), ToJSON (toJSON), Value (..), defaultOptions, encode, genericParseJSON, genericToJSON, withText)
import Data.Aeson.Lens (_String)
import Data.Aeson.Types (parseFail)
import Data.Aeson.Types qualified
import Data.ByteString qualified as BS
import Data.Function ((&))
import Data.Functor (void)
import Data.Generics.Labels ()
import Data.Hashable (Hashable)
import Data.Maybe (fromJust, fromMaybe)
import Data.Scientific (toBoundedInteger)
import Data.String (IsString)
import Data.Text (Text, unpack)
import Data.Text qualified as T
import Data.Text qualified as Text
import Data.Versions (SemVer (..), prettySemVer, semver')
import Data.Void (Void)
import GHC.Generics (C, D, Generic (..), K1 (..), M1 (..), S, Selector (..), U1 (..), (:*:) (..))
import Prettyprinter (Pretty (..), viaShow)
import PyF (PyFCategory (PyFString), PyFClassify, fmt)
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

newtype PlatformHumanReadable
  = PlatformHumanReadable {platform :: Platform}
  deriving newtype (Show, Eq, Ord)
  deriving stock (Generic)
  deriving anyclass (Hashable)

newtype IsRelease = IsRelease {isRelease :: Bool}
  deriving stock (Generic, Eq, Ord, Show)
  deriving newtype (Hashable)

-- | A simple config that is enough to fetch an extension
data ExtensionConfig = ExtensionConfig
  { publisher :: Publisher
  , name :: Name
  , isRelease :: IsRelease
  , platform :: Platform
  , version :: Version
  , engineVersion :: EngineVersion
  , missingTimes :: Int
  }
  deriving stock (Generic, Show, Eq, Ord)
  deriving anyclass (Hashable, GToOrderedKeysJsonBs)

-- | Full necessary info about an extension
data ExtensionInfo = ExtensionInfo
  { publisher :: Publisher
  , name :: Name
  -- ^ engine version that's required to run this extension
  --
  -- See [Visual Studio Code compatibility](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#visual-studio-code-compatibility)
  , isRelease :: IsRelease
  , platform :: Platform
  , version :: Version
  , engineVersion :: EngineVersion
  , sha256 :: Text
  , missingTimes :: Int
  -- ^ how many times the extension could not be fetched
  }
  deriving stock (Generic, Show, Eq, Ord)
  deriving anyclass (Hashable, GToOrderedKeysJsonBs)

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

_PlatformHumanReadable :: Prism' Text Platform
_PlatformHumanReadable = prism' embed_ match_
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

_PlatformNumeric :: Prism' Int Platform
_PlatformNumeric = prism' embed_ match_
 where
  embed_ :: Platform -> Int
  embed_ = \case
    PUniversal -> 0
    PLinux_x64 -> 1
    PLinux_arm64 -> 2
    PDarwin_x64 -> 3
    PDarwin_arm64 -> 4
  match_ :: Int -> Maybe Platform
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
    [fmt|{review _VersionModifier _modifier}{prettySemVer _version}|]
  match_ = TM.parseMaybe parseEngineVersion

_IsReleaseNumeric :: Prism' Int IsRelease
_IsReleaseNumeric = prism' embed_ match_
 where
  embed_ (IsRelease t)
    | t = 1
    | otherwise = 0
  match_ x =
    IsRelease
      <$> case x of
        0 -> Just False
        1 -> Just True
        _ -> Nothing

type Parser = Parsec Void Text

-- | Parse a SemVer-like 'Version'.
--
-- Allow leading zeros.
--
-- >>> TM.parseMaybe parseVersion <$> exampleExtensionVersions
-- [Just 2022.9.290700,Just 23.3.0-canary-open-0313-1900,Just 1.0.0-beta.1,Just 1.13.1712347770,Just 0.1.8+vizcar]
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

exampleExtensionVersions :: [Text]
exampleExtensionVersions =
  [ "2022.09.290700"
  , "23.3.0-canary-open-0313-1900"
  , "1.0.0-beta.1"
  , "1.13.1712347770"
  , "0.1.8+vizcar"
  ]

-- TODO
-- disallow -insiders suffix?

-- | Parse 'EngineVersion'
--
-- >>> TM.parseMaybe parseEngineVersion <$> exampleEngineVersions
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
exampleEngineVersions :: [Text]
exampleEngineVersions =
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
extFlagsAllowed = enumFrom minBound ^.. traversed . Lens.to (_Flags #)

type a # b = a

-- | Select an action depending on a target
targetSelect :: Target -> p # "VSCodeMarketplace" -> p # "OpenVSX" -> p
targetSelect target f g =
  case target of
    VSCodeMarketplace -> f
    OpenVSX -> g

-- | Possible action statuses
ppTarget :: Target -> Text
ppTarget x = targetSelect x "VSCode Marketplace" "Open VSX"

type instance PyFClassify Target = 'PyFString
type instance PyFClassify Version = 'PyFString
type instance PyFClassify Platform = 'PyFString
type instance PyFClassify Name = 'PyFString
type instance PyFClassify Publisher = 'PyFString
type instance PyFClassify EngineVersion = 'PyFString

fieldLabelModifier' :: String -> String
fieldLabelModifier' = \case
  "publisher" -> "p"
  "name" -> "n"
  "isRelease" -> "r"
  "platform" -> "s"
  "version" -> "v"
  "engineVersion" -> "e"
  "sha256" -> "h"
  "missingTimes" -> "m"
  x -> error [fmt|Field not found: {x}|]

optionsExtensionInfo :: Options
optionsExtensionInfo =
  defaultOptions
    { fieldLabelModifier = fieldLabelModifier'
    }

class GFields f where
  gFields :: f p -> [(String, Value)]

instance (GFields f) => GFields (M1 D c f) where
  gFields (M1 x) = gFields x

instance (GFields f) => GFields (M1 C c f) where
  gFields (M1 x) = gFields x

instance (GFields f, GFields g) => GFields (f :*: g) where
  gFields (f :*: g) = gFields f ++ gFields g

instance GFields U1 where
  gFields U1 = []

instance (Selector s, ToJSON c) => GFields (M1 S s (K1 i c)) where
  gFields s@(M1 (K1 val)) = [(selName s, toJSON val)]

class (Generic f, GFields (Rep f)) => GToOrderedKeysJsonBs f where
  gToJsonOrderedKeys :: Options -> f -> BS.ByteString
  gToJsonOrderedKeys opts x = result
   where
    fieldValues = x & from & gFields & traversed . _1 %~ opts.fieldLabelModifier
    result = "{" <> BS.intercalate "," [[fmt|"{k}":{encode v}|] | (k, v) <- fieldValues] <> "}"

class (GToOrderedKeysJsonBs f) => ToOrderedKeysJsonBs f where
  toJsonOrderedKeys :: f -> BS.ByteString

instance ToOrderedKeysJsonBs ExtensionInfo where
  toJsonOrderedKeys = gToJsonOrderedKeys optionsExtensionInfo

instance FromJSON ExtensionInfo where
  parseJSON = genericParseJSON optionsExtensionInfo

instance FromJSON ExtensionConfig where
  parseJSON = genericParseJSON optionsExtensionInfo

instance ToJSON ExtensionConfig where
  toJSON = genericToJSON optionsExtensionInfo

instance ToOrderedKeysJsonBs ExtensionConfig where
  toJsonOrderedKeys = gToJsonOrderedKeys optionsExtensionInfo

instance FromJSON IsRelease where
  parseJSON (Number n) =
    case n ^? Lens.to toBoundedInteger . _Just . _IsReleaseNumeric of
      Just x -> pure x
      Nothing -> parseFail "Could not parse release."
  parseJSON _ = parseFail "Could not parse release. Expected a number."

instance ToJSON IsRelease where
  toJSON = Number . fromIntegral . (_IsReleaseNumeric #)

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
  parseJSON (Number n) =
    case n ^? Lens.to toBoundedInteger . _Just . _PlatformNumeric of
      Just n' -> pure n'
      Nothing -> parseFail "Could not parse platform"
  parseJSON _ = parseFail "Expected a string"

instance FromJSON PlatformHumanReadable where
  parseJSON :: Value -> Data.Aeson.Types.Parser PlatformHumanReadable
  parseJSON (String s) =
    case s ^? _PlatformHumanReadable . Lens.to PlatformHumanReadable of
      Just n' -> pure n'
      Nothing -> parseFail "Could not parse platform"
  parseJSON _ = parseFail "Expected a string"

instance ToJSON Platform where
  toJSON :: Platform -> Value
  toJSON = Number . fromIntegral . (_PlatformNumeric #)

instance Show Platform where
  show :: Platform -> String
  show = unpack . (_PlatformHumanReadable #)

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

instance Pretty ExtensionConfig where
  pretty = viaShow
