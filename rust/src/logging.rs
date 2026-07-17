use crate::config::LogSeverity;

#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum Level {
    Debug,
    Info,
    Warning,
    Error,
}

impl From<LogSeverity> for Level {
    fn from(value: LogSeverity) -> Self {
        match value {
            LogSeverity::Debug => Level::Debug,
            LogSeverity::Info => Level::Info,
            LogSeverity::Warning => Level::Warning,
            LogSeverity::Error => Level::Error,
        }
    }
}

pub trait Logger: Send + Sync {
    fn enabled(&self, level: Level) -> bool;
    fn log(&self, level: Level, message: &str);
}

#[derive(Clone, Copy, Debug)]
pub struct StdoutLogger {
    min_level: Level,
}

impl StdoutLogger {
    pub fn new(min_level: Level) -> Self {
        Self { min_level }
    }
}

impl Logger for StdoutLogger {
    fn enabled(&self, level: Level) -> bool {
        level >= self.min_level
    }

    fn log(&self, level: Level, message: &str) {
        if self.enabled(level) {
            println!("{message}");
        }
    }
}

pub fn stage(label: &str, message: &str) -> String {
    format!("[{label}] {message}")
}

