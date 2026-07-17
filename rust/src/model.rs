use semver::Version as SemVer;
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use std::cmp::Ordering;
use std::fmt::{self, Display};
use std::str::FromStr;

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Target {
    VscodeMarketplace,
    OpenVsx,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub enum Platform {
    Universal,
    LinuxX64,
    LinuxArm64,
    DarwinX64,
    DarwinArm64,
}

impl Platform {
    pub fn as_number(self) -> u8 {
        match self {
            Platform::Universal => 0,
            Platform::LinuxX64 => 1,
            Platform::LinuxArm64 => 2,
            Platform::DarwinX64 => 3,
            Platform::DarwinArm64 => 4,
        }
    }
}

impl Display for Platform {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            Platform::Universal => "universal",
            Platform::LinuxX64 => "linux-x64",
            Platform::LinuxArm64 => "linux-arm64",
            Platform::DarwinX64 => "darwin-x64",
            Platform::DarwinArm64 => "darwin-arm64",
        })
    }
}

impl Serialize for Platform {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_u8(self.as_number())
    }
}

impl<'de> Deserialize<'de> for Platform {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        match u8::deserialize(deserializer)? {
            0 => Ok(Platform::Universal),
            1 => Ok(Platform::LinuxX64),
            2 => Ok(Platform::LinuxArm64),
            3 => Ok(Platform::DarwinX64),
            4 => Ok(Platform::DarwinArm64),
            other => Err(serde::de::Error::custom(format!("invalid platform: {other}"))),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct IsRelease(pub bool);

impl IsRelease {
    pub fn as_number(self) -> u8 {
        if self.0 { 1 } else { 0 }
    }
}

impl Serialize for IsRelease {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_u8(self.as_number())
    }
}

impl<'de> Deserialize<'de> for IsRelease {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        match u8::deserialize(deserializer)? {
            0 => Ok(IsRelease(false)),
            1 => Ok(IsRelease(true)),
            other => Err(serde::de::Error::custom(format!("invalid isRelease: {other}"))),
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct Name(pub String);

impl Display for Name {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl Serialize for Name {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.0)
    }
}

impl<'de> Deserialize<'de> for Name {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        Ok(Name(String::deserialize(deserializer)?))
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct Publisher(pub String);

impl Display for Publisher {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl Serialize for Publisher {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.0)
    }
}

impl<'de> Deserialize<'de> for Publisher {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        Ok(Publisher(String::deserialize(deserializer)?))
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Version {
    raw: String,
    parsed: SemVer,
}

impl Version {
    pub fn raw(&self) -> &str {
        &self.raw
    }

    pub fn parse(input: &str) -> Result<Self, String> {
        let mut parts = input.split('.').collect::<Vec<_>>();
        if parts.len() < 3 {
            return Err(format!("invalid version: {input}"));
        }
        let tail = parts.split_off(3);
        let major = parse_u64_prefix(parts[0]).ok_or_else(|| format!("invalid version: {input}"))?;
        let minor = parse_u64_prefix(parts[1]).ok_or_else(|| format!("invalid version: {input}"))?;
        let (patch, patch_suffix) =
            parse_u64_prefix_and_suffix(parts[2]).ok_or_else(|| format!("invalid version: {input}"))?;
        let rest = if tail.is_empty() {
            patch_suffix
        } else {
            format!("{patch_suffix}.{}", tail.join("."))
        };
        let semver_text = format!("{major}.{minor}.{}{}", patch, rest);
        let parsed = SemVer::from_str(&semver_text).map_err(|err| err.to_string())?;
        Ok(Version {
            raw: input.to_string(),
            parsed,
        })
    }
}

fn parse_u64_prefix(input: &str) -> Option<u64> {
    parse_u64_prefix_and_suffix(input).map(|(n, _)| n)
}

fn parse_u64_prefix_and_suffix(input: &str) -> Option<(u64, String)> {
    let digits = input.chars().take_while(|c| c.is_ascii_digit()).collect::<String>();
    if digits.is_empty() {
        None
    } else {
        let rest = input.chars().skip(digits.len()).collect::<String>();
        digits.parse().ok().map(|n| (n, rest))
    }
}

impl Display for Version {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.raw)
    }
}

impl Ord for Version {
    fn cmp(&self, other: &Self) -> Ordering {
        self.parsed.cmp(&other.parsed).then(self.raw.cmp(&other.raw))
    }
}

impl PartialOrd for Version {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl Serialize for Version {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.raw)
    }
}

impl<'de> Deserialize<'de> for Version {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let raw = String::deserialize(deserializer)?;
        Version::parse(&raw).map_err(serde::de::Error::custom)
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub enum EngineVersionModifier {
    Eq,
    Gte,
}

impl Display for EngineVersionModifier {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            EngineVersionModifier::Eq => "",
            EngineVersionModifier::Gte => "^",
        })
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub struct EngineVersion {
    pub modifier: EngineVersionModifier,
    pub version: SemVer,
}

impl EngineVersion {
    pub fn parse(input: &str) -> Result<Self, String> {
        if input == "*" {
            return Ok(Self {
                modifier: EngineVersionModifier::Gte,
                version: SemVer::new(0, 0, 0),
            });
        }

        let (modifier, rest) = if let Some(rest) = input.strip_prefix("^") {
            (EngineVersionModifier::Gte, rest)
        } else if let Some(rest) = input.strip_prefix(">=") {
            (EngineVersionModifier::Gte, rest)
        } else {
            (EngineVersionModifier::Eq, input)
        };

        let parts = rest.split('.').collect::<Vec<_>>();
        if parts.len() != 3 {
            return Err(format!("invalid engine version: {input}"));
        }
        let (major, _) = parse_engine_component(parts[0])?;
        let (minor, _) = parse_engine_component(parts[1])?;
        let (patch, patch_suffix) = parse_engine_component(parts[2])?;
        let semver_text = format!("{major}.{minor}.{}{}", patch, patch_suffix);
        let version = SemVer::from_str(&semver_text).map_err(|err| err.to_string())?;
        Ok(Self { modifier, version })
    }
}

fn parse_engine_component(input: &str) -> Result<(u64, String), String> {
    if input == "x" {
        return Ok((0, String::new()));
    }
    parse_u64_prefix_and_suffix(input)
        .ok_or_else(|| format!("invalid engine version component: {input}"))
}

impl Display for EngineVersion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}{}", self.modifier, self.version)
    }
}

impl Serialize for EngineVersion {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

impl<'de> Deserialize<'de> for EngineVersion {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let raw = String::deserialize(deserializer)?;
        EngineVersion::parse(&raw).map_err(serde::de::Error::custom)
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Serialize, Deserialize)]
pub struct ExtensionConfig {
    #[serde(rename = "p")]
    pub publisher: Publisher,
    #[serde(rename = "n")]
    pub name: Name,
    #[serde(rename = "r")]
    pub is_release: IsRelease,
    #[serde(rename = "P")]
    pub platform: Platform,
    #[serde(rename = "v")]
    pub version: Version,
    #[serde(rename = "e")]
    pub engine_version: EngineVersion,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Serialize, Deserialize)]
pub struct CacheRecord {
    #[serde(rename = "p")]
    pub publisher: Publisher,
    #[serde(rename = "n")]
    pub name: Name,
    #[serde(rename = "r")]
    pub is_release: IsRelease,
    #[serde(rename = "P")]
    pub platform: Platform,
    #[serde(rename = "v")]
    pub version: Version,
    #[serde(rename = "e")]
    pub engine_version: EngineVersion,
    #[serde(rename = "h")]
    pub hash: String,
}

impl CacheRecord {
    pub fn key_full(&self) -> (Publisher, Name, IsRelease, Platform, Version) {
        (
            self.publisher.clone(),
            self.name.clone(),
            self.is_release,
            self.platform,
            self.version.clone(),
        )
    }

    pub fn key_latest(&self) -> (Publisher, Name, IsRelease, Platform) {
        (
            self.publisher.clone(),
            self.name.clone(),
            self.is_release,
            self.platform,
        )
    }
}

impl ExtensionConfig {
    pub fn key_full(&self) -> (Publisher, Name, IsRelease, Platform, Version) {
        (
            self.publisher.clone(),
            self.name.clone(),
            self.is_release,
            self.platform,
            self.version.clone(),
        )
    }

    pub fn key_latest(&self) -> (Publisher, Name, IsRelease, Platform) {
        (
            self.publisher.clone(),
            self.name.clone(),
            self.is_release,
            self.platform,
        )
    }
}

pub fn sort_latest_key(a: &CacheRecord, b: &CacheRecord) -> Ordering {
    a.publisher
        .0
        .cmp(&b.publisher.0)
        .then(a.name.0.cmp(&b.name.0))
        .then(a.is_release.cmp(&b.is_release))
        .then(a.platform.cmp(&b.platform))
        .then(a.version.cmp(&b.version))
}
