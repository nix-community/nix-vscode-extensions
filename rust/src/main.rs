use clap::Parser;
use nix_vscode_extensions_updater::{
    config::AppConfig,
    logging::{Level, StdoutLogger},
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
    let logger = StdoutLogger::new(Level::from(config.log_severity));
    let marketplace = HttpMarketplaceClient::new(config.program_timeout)?;
    let prefetcher = NixPrefetcher;
    let pipeline = Pipeline {
        config: &config,
        marketplace: &marketplace,
        prefetcher: &prefetcher,
        logger: &logger,
    };
    pipeline.run()
}
