use anyhow::Context;
use clap::Parser;
use nix_vscode_extensions_updater::{
    config::AppConfig,
    logging::{init_tracing, lifecycle_field, render_effective_config, Lifecycle},
    marketplace::HttpMarketplaceClient,
    pipeline::{Pipeline, ShutdownSignal},
    prefetch::NixPrefetcher,
};
use std::path::PathBuf;
use std::sync::Arc;

#[derive(Parser)]
struct Args {
    #[arg(long)]
    config: Option<PathBuf>,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let config = AppConfig::load(args.config.as_deref())?;
    init_tracing(&config)?;
    tracing::info!(
        stage = "run",
        lifecycle = lifecycle_field(Lifecycle::Info),
        summary = %format!("Effective config\n{}", render_effective_config(&config)?)
    );
    let marketplace = HttpMarketplaceClient::new(config.program_timeout)?;
    let prefetcher = NixPrefetcher;
    let shutdown = Arc::new(ShutdownSignal::new());
    let shutdown_handler = shutdown.clone();
    ctrlc::set_handler(move || shutdown_handler.request()).context("failed to register shutdown handler")?;
    let pipeline = Pipeline {
        config: &config,
        marketplace: &marketplace,
        prefetcher: &prefetcher,
        shutdown: shutdown.as_ref(),
    };
    pipeline.run()
}
