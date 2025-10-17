// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use futures::stream::FuturesUnordered;
use std::collections::BTreeMap;
use std::sync::Arc;
use sui_types::base_types::{ObjectID, ObjectRef, SuiAddress, SUI_ADDRESS_LENGTH};
use sui_types::crypto::{get_account_key_pair, AccountKeyPair};
use sui_types::object::Object;
use csv::StringRecord;

#[derive(Clone)]
#[derive(Debug)]
pub struct Account {
    pub sender: SuiAddress,
    pub keypair: Arc<AccountKeyPair>,
    pub gas_objects: Arc<Vec<ObjectRef>>,
}

/// Generate \num_accounts accounts and for each account generate \gas_object_num_per_account gas objects.
/// Return all accounts along with a flattened list of all gas objects as genesis objects.
pub async fn batch_create_account_and_gas(
    num_accounts: u64,
    gas_object_num_per_account: u64,
) -> (BTreeMap<SuiAddress, Account>, Vec<Object>) {
    let tasks: FuturesUnordered<_> = (0..num_accounts)
        .map(|idx| {
            let starting_id = idx * gas_object_num_per_account;
            tokio::spawn(async move {
                let (sender, keypair) = get_account_key_pair();
                let objects = (0..gas_object_num_per_account)
                    .map(|i| new_gas_object(starting_id + i, sender))
                    .collect::<Vec<_>>();
                (sender, keypair, objects)
            })
        })
        .collect();
    let mut accounts = BTreeMap::new();
    let mut genesis_gas_objects = vec![];
    for task in tasks {
        let (sender, keypair, gas_objects) = task.await.unwrap();
        let gas_object_refs: Vec<_> = gas_objects
            .iter()
            .map(|o| o.compute_object_reference())
            .collect();
        accounts.insert(
            sender,
            Account {
                sender,
                keypair: Arc::new(keypair),
                gas_objects: Arc::new(gas_object_refs),
            },
        );
        genesis_gas_objects.extend(gas_objects);
    }
    (accounts, genesis_gas_objects)
}

pub async fn batch_create_account_and_gas_by_index(
    records: Vec<StringRecord>
) -> (BTreeMap<SuiAddress, Account>, Vec<Object>, BTreeMap<u64, SuiAddress>, Account) {
    let mut starting_id = 1;
    let tasks: FuturesUnordered<_> = records.iter().map(|record| {
        let addr_index:u64 = record[0].parse().unwrap();
        let mut obj_num:u64 = record[1].parse().unwrap();
        // + gas obj
        obj_num = obj_num * 2;
        let task = tokio::spawn(async move {
            let account = get_account_key_pair();
            let gas_objects = create_gas_objects(account.0, obj_num, starting_id);
            (addr_index, account, gas_objects)
        });
        starting_id = starting_id + obj_num;
        task
    }).collect();

    let mut accounts = BTreeMap::new();
    let mut genesis_gas_objects = vec![];
    let mut account_indexes:BTreeMap<u64, SuiAddress> = BTreeMap::new();
    for task in tasks {
        let (addr_index, account, gas_objects) = task.await.unwrap();
        let gas_object_refs: Vec<_> = gas_objects
            .iter()
            .map(|o| o.compute_object_reference())
            .collect();
        
        accounts.insert(
            account.0,
            Account {
                sender: account.0,
                keypair: Arc::new(account.1),
                gas_objects: Arc::new(gas_object_refs),
            },
        );
        account_indexes.insert(addr_index, account.0);

        genesis_gas_objects.extend(gas_objects);
    }
    let admain_account = get_account_key_pair();
    let admain_gas_objects = create_gas_objects(admain_account.0, 1, 10000000000000000);
    let admain_gas_object_refs: Vec<_> = admain_gas_objects
            .iter()
            .map(|o| o.compute_object_reference())
            .collect();
    let admain = Account {
        sender: admain_account.0,
        keypair: Arc::new(admain_account.1),
        gas_objects: Arc::new(admain_gas_object_refs),
    };
    genesis_gas_objects.extend(admain_gas_objects);

    (accounts, genesis_gas_objects, account_indexes, admain)
}

fn create_gas_objects(sender: SuiAddress, num: u64, starting_id: u64) -> Vec<Object> {
    let objects = (0..num)
        .map(|i| new_gas_object(starting_id + i, sender))
        .collect::<Vec<_>>();
    objects
}

fn new_gas_object(idx: u64, owner: SuiAddress) -> Object {
    // Predictable and cheaper way of generating object IDs for benchmarking.
    let mut id_bytes = [0u8; SUI_ADDRESS_LENGTH];
    let idx_bytes = idx.to_le_bytes();
    id_bytes[0] = 255;
    id_bytes[1..idx_bytes.len() + 1].copy_from_slice(&idx_bytes);
    let object_id = ObjectID::from_bytes(id_bytes).unwrap();
    Object::with_id_owner_for_testing(object_id, owner)
}
