// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use clap::Parser;
use sui_single_node_benchmark::command::Command;
use sui_single_node_benchmark::run_benchmark;
use sui_single_node_benchmark::run_kitty_test;
use sui_single_node_benchmark::workload::Workload;

#[tokio::main]
async fn main() {
    let _guard = telemetry_subscribers::TelemetryConfig::new()
        .with_log_level("off,sui_single_node_benchmark=info")
        .with_env()
        .init();

    let args = Command::parse();
    let wl = Workload::new(args.tx_count, args.workload);
    if wl.is_test_kitty() {
        run_kitty_test(
            wl,
            args.component,
            args.print_sample_tx,
            args.skip_signing,
            args.account_path,
        )
        .await;
    } else {
        run_benchmark(
            wl,
            args.component,
            args.checkpoint_size,
            args.print_sample_tx,
            args.skip_signing,
            args.erc20_tx_path,
            args.account_path,
        )
        .await;
    }
    

    if std::env::var("TRACE_FILTER").is_ok() {
        println!("Sleeping for 60 seconds to allow tracing to flush.");
        println!("You can ctrl-c to exit once you see trace data appearing in grafana");
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
    }
}
