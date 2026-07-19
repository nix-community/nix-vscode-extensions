use crate::config::{AppConfig, LogSeverity};
use anstream::AutoStream;
use serde_json::to_string_pretty;
use std::fmt;
use std::io::{self, Stdout};
use tracing::{Event, Level, Subscriber};
use tracing_subscriber::filter::LevelFilter;
use tracing_subscriber::fmt::format::{FormatEvent, FormatFields, Writer};
use tracing_subscriber::fmt::FmtContext;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::prelude::*;
use tracing_subscriber::registry::LookupSpan;

const FIELD_LIFECYCLE: &str = "lifecycle";
const FIELD_STAGE: &str = "stage";
const FIELD_SUMMARY: &str = "summary";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Lifecycle {
    Start,
    Finish,
    Info,
}

impl Lifecycle {
    fn as_str(self) -> &'static str {
        match self {
            Lifecycle::Start => "start",
            Lifecycle::Finish => "finish",
            Lifecycle::Info => "info",
        }
    }

    fn marker(self) -> &'static str {
        match self {
            Lifecycle::Start => "START",
            Lifecycle::Finish => "FINISH",
            Lifecycle::Info => "INFO",
        }
    }
}

#[derive(Clone, Copy, Debug, Default)]
pub struct HumanFormatter;

#[derive(Clone, Debug, Default)]
struct EventFields {
    lifecycle: Option<String>,
    stage: Option<String>,
    summary: Option<String>,
    rest: Vec<(String, String)>,
}

#[derive(Default)]
struct FieldVisitor {
    fields: EventFields,
}

impl tracing::field::Visit for FieldVisitor {
    fn record_str(&mut self, field: &tracing::field::Field, value: &str) {
        self.record_value(field.name(), value.to_string());
    }

    fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn fmt::Debug) {
        self.record_value(field.name(), format!("{value:?}"));
    }
}

impl FieldVisitor {
    fn record_value(&mut self, name: &str, value: String) {
        match name {
            FIELD_LIFECYCLE => self.fields.lifecycle = Some(value),
            FIELD_STAGE => self.fields.stage = Some(value),
            FIELD_SUMMARY => self.fields.summary = Some(value),
            "message" => {
                if self.fields.summary.is_none() {
                    self.fields.summary = Some(trim_debug_string(&value));
                }
            }
            _ => self.fields.rest.push((name.to_string(), trim_debug_string(&value))),
        }
    }
}

fn trim_debug_string(input: &str) -> String {
    if input.starts_with('"') && input.ends_with('"') && input.len() >= 2 {
        input[1..input.len() - 1].to_string()
    } else {
        input.to_string()
    }
}

pub fn level_filter(severity: LogSeverity) -> LevelFilter {
    match severity {
        LogSeverity::Debug => LevelFilter::DEBUG,
        LogSeverity::Info => LevelFilter::INFO,
        LogSeverity::Warning => LevelFilter::WARN,
        LogSeverity::Error => LevelFilter::ERROR,
    }
}

pub fn render_effective_config(config: &AppConfig) -> anyhow::Result<String> {
    Ok(to_string_pretty(config)?)
}

pub fn init_tracing(config: &AppConfig) -> anyhow::Result<()> {
    let writer = || AutoStream::new(io::stdout(), anstream::ColorChoice::Auto);
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::fmt::layer()
                .event_format(HumanFormatter)
                .with_writer(writer)
                .with_filter(level_filter(config.log_severity)),
        )
        .try_init()?;
    Ok(())
}

impl<S, N> FormatEvent<S, N> for HumanFormatter
where
    S: Subscriber + for<'span> LookupSpan<'span>,
    N: for<'writer> FormatFields<'writer> + 'static,
{
    fn format_event(
        &self,
        _ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &Event<'_>,
    ) -> fmt::Result {
        let mut visitor = FieldVisitor::default();
        event.record(&mut visitor);
        let fields = visitor.fields;
        let level = *event.metadata().level();
        let lifecycle = match fields.lifecycle.as_deref() {
            Some("start") => Lifecycle::Start,
            Some("finish") => Lifecycle::Finish,
            _ => Lifecycle::Info,
        };

        write_level(&mut writer, level)?;
        write!(writer, " [ {:^6} ] ", lifecycle.marker())?;
        write!(writer, "[{}] ", fields.stage.as_deref().unwrap_or("general"))?;
        if let Some(summary) = fields.summary {
            write!(writer, "{summary}")?;
        }
        for (key, value) in fields.rest {
            write!(writer, " {key}={value}")?;
        }
        if level == Level::DEBUG {
            let meta = event.metadata();
            if let (Some(file), Some(line)) = (meta.file(), meta.line()) {
                write!(writer, " ({file}:{line})")?;
            } else if let Some(module) = meta.module_path() {
                write!(writer, " ({module})")?;
            }
        }
        writeln!(writer)
    }
}

fn write_level(writer: &mut Writer<'_>, level: Level) -> fmt::Result {
    let has_ansi = writer.has_ansi_escapes();
    let (prefix, suffix) = if has_ansi {
        match level {
            Level::ERROR => ("\u{1b}[31;1m", "\u{1b}[0m"),
            Level::WARN => ("\u{1b}[33;1m", "\u{1b}[0m"),
            Level::INFO => ("\u{1b}[32;1m", "\u{1b}[0m"),
            Level::DEBUG => ("\u{1b}[36;1m", "\u{1b}[0m"),
            Level::TRACE => ("", ""),
        }
    } else {
        ("", "")
    };
    write!(writer, "{prefix}{:<5}{suffix}", level.as_str())
}

pub fn lifecycle_field(lifecycle: Lifecycle) -> &'static str {
    lifecycle.as_str()
}

pub type StdoutLogWriter = AutoStream<Stdout>;

#[cfg(test)]
mod tests {
    use super::{level_filter, lifecycle_field, render_effective_config, HumanFormatter, Lifecycle};
    use crate::config::{AppConfig, LogSeverity};
    use std::io::{self, Write};
    use std::sync::{Arc, Mutex};
    use tracing_subscriber::fmt;
    use tracing_subscriber::layer::SubscriberExt;
    use tracing_subscriber::prelude::*;

    #[derive(Clone, Default)]
    struct SharedWriter {
        bytes: Arc<Mutex<Vec<u8>>>,
    }

    impl SharedWriter {
        fn rendered(&self) -> String {
            String::from_utf8(self.bytes.lock().unwrap().clone()).unwrap()
        }
    }

    struct SharedGuard {
        bytes: Arc<Mutex<Vec<u8>>>,
    }

    impl Write for SharedGuard {
        fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
            self.bytes.lock().unwrap().extend_from_slice(buf);
            Ok(buf.len())
        }

        fn flush(&mut self) -> io::Result<()> {
            Ok(())
        }
    }

    impl<'a> tracing_subscriber::fmt::writer::MakeWriter<'a> for SharedWriter {
        type Writer = SharedGuard;

        fn make_writer(&'a self) -> Self::Writer {
            SharedGuard {
                bytes: self.bytes.clone(),
            }
        }
    }

    fn render<F>(severity: LogSeverity, emit: F) -> String
    where
        F: FnOnce(),
    {
        let writer = SharedWriter::default();
        let subscriber = tracing_subscriber::registry().with(
            fmt::layer()
                .event_format(HumanFormatter)
                .with_writer(writer.clone())
                .with_filter(level_filter(severity)),
        );
        tracing::subscriber::with_default(subscriber, emit);
        writer.rendered()
    }

    #[test]
    fn formatter_renders_info_warn_error_and_debug_levels() {
        let rendered = render(LogSeverity::Debug, || {
            tracing::info!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "info line");
            tracing::warn!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "warn line");
            tracing::error!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "error line");
            tracing::debug!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "debug line");
        });
        assert!(rendered.contains("INFO  [  INFO  ] [run] info line"));
        assert!(rendered.contains("WARN  [  INFO  ] [run] warn line"));
        assert!(rendered.contains("ERROR [  INFO  ] [run] error line"));
        assert!(rendered.contains("DEBUG [  INFO  ] [run] debug line"));
    }

    #[test]
    fn formatter_renders_lifecycle_markers() {
        let rendered = render(LogSeverity::Info, || {
            tracing::info!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Start), summary = "start line");
            tracing::info!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Finish), summary = "finish line");
        });
        assert!(rendered.contains("[ START  ] [run] start line"));
        assert!(rendered.contains("[ FINISH ] [run] finish line"));
    }

    #[test]
    fn formatter_disables_color_for_captured_output() {
        let rendered = render(LogSeverity::Info, || {
            tracing::info!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "plain");
        });
        assert!(!rendered.contains("\u{1b}["));
    }

    #[test]
    fn formatter_renders_callsite_for_debug_events_only() {
        let rendered = render(LogSeverity::Debug, || {
            tracing::debug!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "debug");
            tracing::info!(stage = "run", lifecycle = lifecycle_field(Lifecycle::Info), summary = "info");
        });
        assert!(rendered.contains("debug ("));
        let info_line = rendered
            .lines()
            .find(|line| line.contains("[run] info"))
            .unwrap();
        assert!(!info_line.contains(" ("));
    }

    #[test]
    fn formatter_can_log_full_config() {
        let config = AppConfig::default();
        let rendered = render(LogSeverity::Info, || {
            tracing::info!(
                stage = "run",
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!("Effective config\n{}", render_effective_config(&config).unwrap())
            );
        });
        assert!(rendered.contains("Effective config"));
        assert!(rendered.contains("\"processed_logger_delay\""));
        assert!(rendered.contains("\"open_vsx\""));
    }
}
