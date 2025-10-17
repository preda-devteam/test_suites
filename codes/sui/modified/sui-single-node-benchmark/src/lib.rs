// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashMap;
use std::time::Instant;

use futures::stream::FuturesUnordered;
use futures::StreamExt;
use sui_types::effects::{TransactionEffects, TransactionEffectsAPI};
use tracing::info;

use crate::benchmark_context::BenchmarkContext;
use crate::command::Component;
use crate::workload::Workload;

pub(crate) mod benchmark_context;
pub mod command;
pub(crate) mod mock_account;
pub(crate) mod mock_consensus;
pub(crate) mod mock_storage;
pub(crate) mod single_node;
pub(crate) mod tx_generator;
pub mod workload;
pub mod csv;

/// Benchmark a given workload on a specified component.
/// The different kinds of workloads and components can be found in command.rs.
/// \checkpoint_size represents both the size of a consensus commit, and size of a checkpoint
/// if we are benchmarking the checkpoint.
pub async fn run_benchmark(
    workload: Workload,
    component: Component,
    checkpoint_size: usize,
    print_sample_tx: bool,
    skip_signing: bool,
    erc20_tx_path: String,
    account_path: String
) {
    let mut ctx = BenchmarkContext::new(workload.clone(), component, print_sample_tx, account_path).await;
    let tx_generator = workload.create_tx_generator(&mut ctx).await;
    
    let transactions = {
        if erc20_tx_path.is_empty() {
            ctx.generate_transactions(tx_generator).await
        } else {
            ctx.generate_erc20_tx_from_csv(tx_generator, erc20_tx_path).await
        }
    };

    if matches!(component, Component::TxnSigning) {
        ctx.benchmark_transaction_signing(transactions, print_sample_tx)
            .await;
        return;
    }

    let transactions = ctx.certify_transactions(transactions, skip_signing).await;
    ctx.validator()
        .assigned_shared_object_versions(&transactions)
        .await;
    match component {
        Component::CheckpointExecutor => {
            ctx.benchmark_checkpoint_executor(transactions, checkpoint_size)
                .await;
        }
        Component::ExecutionOnly => {
            ctx.benchmark_transaction_execution_in_memory(transactions, print_sample_tx)
                .await;
        }
        _ => {
            ctx.benchmark_transaction_execution(transactions, print_sample_tx)
                .await;
        }
    }
}


pub async fn run_kitty_test(
    workload: Workload,
    component: Component,
    print_sample_tx: bool,
    skip_signing: bool,
    account_path: String,
) {
    let mut ctx = BenchmarkContext::new(workload.clone(), component, print_sample_tx, account_path).await;
    let tx_generator = workload.create_tx_generator(&mut ctx).await;
    
    // generate provide gene transaction
    let transactions = ctx.generate_kitty_provide_gene_transactions(tx_generator.clone()).await;

    if matches!(component, Component::TxnSigning) {
        ctx.benchmark_transaction_signing(transactions, print_sample_tx)
            .await;
        return;
    }

    let transactions = ctx.certify_transactions(transactions, skip_signing).await;
    ctx.validator()
        .assigned_shared_object_versions(&transactions)
        .await;
    let tx_count = transactions.len();
    let start_time = Instant::now();
    info!("Start executing tx, time: {:?}, tx_count: {}", start_time, tx_count);
    let tasks: FuturesUnordered<_> = transactions
        .into_iter()
        .map(|tx| {
            let validator = ctx.validator();
            let component = ctx.component();
            tokio::spawn(async move { validator.execute_certificate(tx, component).await })
        })
        .collect();
    let results: Vec<_> = tasks.collect().await;
    info!("End executing tx, time: {:?}", Instant::now());
    let elapsed1 = start_time.elapsed().as_millis() as f64 / 1000f64;
    info!(
        "Execution provide_gene finished in {}s, TPS={}",
        elapsed1,
        tx_count as f64 / elapsed1
    );

    // generate gene objects
    let mut new_gas_objects = HashMap::new();
    let mut new_kitty_objects = HashMap::new();
    let mut gene_objects = HashMap::new();
    let validator = ctx.validator();
    let epoch_id = validator.get_epoch_store().epoch();
    let cache_commit = validator.get_validator().get_cache_commit();
    let provide_gene_results: Vec<TransactionEffects> = results.into_iter().map(|r| r.unwrap()).collect();
    for effects in provide_gene_results {
        // info!("provide gene effects:{:?}", effects);
        let (owner, gene_object) = effects
            .created()
            .into_iter()
            .filter_map(|(oref, owner)| {
                owner
                    .get_address_owner_address()
                    .ok()
                    .map(|owner| (owner, oref))
            })
            .next()
            .unwrap();
        gene_objects.insert(owner, gene_object);

        let gas_object = effects.gas_object().0;

        let (owner, new_kitty_object) = effects
            .mutated()
            .into_iter()
            .filter_map(|(oref, owner)| {
                if oref.0 != gas_object.0 {
                    owner
                        .get_address_owner_address()
                        .ok()
                        .map(|owner| (owner, oref))
                } else {
                    None
                }
            })
            .next()
            .unwrap();
        new_kitty_objects.insert(owner, new_kitty_object);
        new_gas_objects.insert(gas_object.0, gas_object);
        // Make sure to commit them to DB. This is needed by both the execution-only mode
        // and the checkpoint-executor mode. For execution-only mode, we iterate through all
        // live objects to construct the in memory object store, hence requiring these objects committed to DB.
        // For checkpoint executor, in order to commit a checkpoint it is required previous versions
        // of objects are already committed.
        cache_commit
            .commit_transaction_outputs(epoch_id, effects.transaction_digest())
            .await
            .unwrap();
    }
    ctx.refresh_gas_objects(new_gas_objects);
    info!("Finished preparing gene objects");
    // info!("new_kitty_objects:{:?}", new_kitty_objects);
    // info!("gene_objects:{:?}", gene_objects);

    // generate breed transactions
    let transactions = ctx.generate_kitty_breed_transactions(tx_generator.clone(), gene_objects, new_kitty_objects).await;
    if matches!(component, Component::TxnSigning) {
        ctx.benchmark_transaction_signing(transactions, print_sample_tx)
            .await;
        return;
    }
    let transactions = ctx.certify_transactions(transactions, skip_signing).await;
    ctx.validator()
        .assigned_shared_object_versions(&transactions)
        .await;
    let tx_count = transactions.len();
    let start_time = Instant::now();
    info!("Start executing tx, time: {:?}, tx_count: {}", start_time, tx_count);
    let tasks: FuturesUnordered<_> = transactions
        .into_iter()
        .map(|tx| {
            let validator = ctx.validator();
            let component = ctx.component();
            tokio::spawn(async move { validator.execute_certificate(tx, component).await })
        })
        .collect();
    let results: Vec<_> = tasks.collect().await;
    results.into_iter().for_each(|r| {
        r.unwrap();
    });
    info!("End executing tx, time: {:?}", Instant::now());
    let elapsed2 = start_time.elapsed().as_millis() as f64 / 1000f64;
    info!(
        "Execution breed finished in {}s, TPS={}",
        elapsed2,
        tx_count as f64 / elapsed1
    );

    println!(
        "Execution kitty all finished in {}s, TPS={}",
        elapsed1 + elapsed2,
        tx_count as f64 / (elapsed1 + elapsed2)
    );


}
