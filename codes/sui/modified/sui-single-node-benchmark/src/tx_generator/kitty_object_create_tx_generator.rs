// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::mock_account::Account;
use crate::tx_generator::TxGenerator;
use sui_test_transaction_builder::TestTransactionBuilder;
use sui_types::base_types::{ObjectID, ObjectRef, SuiAddress};
use sui_types::transaction::{CallArg, Transaction, DEFAULT_VALIDATOR_GAS_PRICE};
use std::collections::HashMap;
use rand::Rng;


pub struct KittyObjectCreateTxGenerator {
    move_package: ObjectID,
}

impl KittyObjectCreateTxGenerator {
    pub fn new(move_package: ObjectID) -> Self {
        Self { move_package }
    }
}

impl TxGenerator for KittyObjectCreateTxGenerator {
    fn generate_tx(&self, account: Account, _to:SuiAddress, _args: HashMap<String, usize>, _objects: Vec<ObjectRef>) -> Transaction {
        let mut rng = rand::thread_rng();
        let gene_id:u128 = rng.gen();
        // println!("gene id:{}", gene_id);
        TestTransactionBuilder::new(
            account.sender,
            account.gas_objects[0],
            DEFAULT_VALIDATOR_GAS_PRICE,
        )
        .move_call(
            self.move_package,
            "KittyBreeding",
            "mint",
            vec![CallArg::Pure(bcs::to_bytes(&gene_id).unwrap())],
        )
        .build_and_sign(account.keypair.as_ref())
    }

    fn name(&self) -> &'static str {
        "Kitty Object Creation Transaction Generator"
    }

    fn shared_obj_num(&self) -> usize {
        return 0;
    }
}
