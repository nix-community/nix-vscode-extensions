mod support;

use nix_vscode_extensions_updater::cache::{read_jsonl_cache, write_jsonl_cache};
use nix_vscode_extensions_updater::model::Platform;
use support::{record, TestEnv};

#[test]
fn jsonl_cache_round_trip_preserves_records_and_skips_blank_lines() {
    let env = TestEnv::new();
    let path = env.data_dir.join("cache.jsonl");
    let records = vec![
        record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-one"),
        record(
            "fresh",
            "ext",
            false,
            Platform::DarwinArm64,
            "2.0.0-insider",
            "sha256-two",
        ),
    ];

    write_jsonl_cache(&path, &records).unwrap();
    let mut contents = std::fs::read_to_string(&path).unwrap();
    contents.push_str("\n\n");
    std::fs::write(&path, contents).unwrap();

    let round_tripped = read_jsonl_cache(&path).unwrap();
    assert_eq!(round_tripped, records);
}

#[test]
fn jsonl_cache_handles_empty_whitespace_and_malformed_input() {
    let env = TestEnv::new();

    let empty = env.data_dir.join("empty.jsonl");
    std::fs::write(&empty, "").unwrap();
    assert!(read_jsonl_cache(&empty).unwrap().is_empty());

    let whitespace = env.data_dir.join("whitespace.jsonl");
    std::fs::write(&whitespace, " \n\t\n").unwrap();
    assert!(read_jsonl_cache(&whitespace).unwrap().is_empty());

    let malformed = env.data_dir.join("malformed.jsonl");
    std::fs::write(&malformed, "{not-json}\n").unwrap();
    assert!(read_jsonl_cache(&malformed).is_err());

    let mixed = env.data_dir.join("mixed.jsonl");
    std::fs::write(
        &mixed,
        format!(
            "{}\n{}\n{}\n",
            serde_json::to_string(&record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-one")).unwrap(),
            "{not-json}",
            serde_json::to_string(&record("fresh", "ext", false, Platform::DarwinArm64, "2.0.0", "sha256-two")).unwrap(),
        ),
    )
    .unwrap();
    assert!(read_jsonl_cache(&mixed).is_err());

    let unreadable = env.data_dir.join("unreadable.jsonl");
    std::fs::create_dir(&unreadable).unwrap();
    assert!(read_jsonl_cache(&unreadable).is_err());
}
