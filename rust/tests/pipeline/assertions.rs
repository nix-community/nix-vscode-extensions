#![allow(dead_code)]

use super::support::TestLogger;

pub fn log_messages(logger: &TestLogger) -> Vec<String> {
    logger.entries().into_iter().map(|entry| entry.message).collect()
}
