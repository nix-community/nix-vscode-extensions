use clap::Parser;
use nix_vscode_extensions_updater::{
    config::AppConfig,
    logging::{init_tracing, lifecycle_field, render_effective_config, Lifecycle},
    marketplace::HttpMarketplaceClient,
    pipeline::Pipeline,
    prefetch::NixPrefetcher,
};
use std::path::PathBuf;

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
    let pipeline = Pipeline {
        config: &config,
        marketplace: &marketplace,
        prefetcher: &prefetcher,
    };
    pipeline.run()
}
