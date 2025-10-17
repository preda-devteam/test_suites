// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::mock_account::Account;
use crate::tx_generator::TxGenerator;
use sui_test_transaction_builder::TestTransactionBuilder;
use sui_types::base_types::{ObjectID, ObjectRef, SuiAddress};
use sui_types::transaction::{Transaction, DEFAULT_VALIDATOR_GAS_PRICE};
use std::collections::HashMap;


pub struct SharedObjectCreateTxGenerator {
    move_package: ObjectID,
}

impl SharedObjectCreateTxGenerator {
    pub fn new(move_package: ObjectID) -> Self {
        Self { move_package }
    }
}

impl TxGenerator for SharedObjectCreateTxGenerator {
    fn generate_tx(&self, account: Account, _to:SuiAddress, _args: HashMap<String, usize>, _objects: Vec<ObjectRef>) -> Transaction {
        TestTransactionBuilder::new(
            account.sender,
            account.gas_objects[0],
            DEFAULT_VALIDATOR_GAS_PRICE,
        )
        .move_call(
            self.move_package,
            "benchmark",
            "create_shared_counter",
            vec![],
        )
        .build_and_sign(account.keypair.as_ref())
    }

    fn name(&self) -> &'static str {
        "Shared Object Creation Transaction Generator"
    }

    fn shared_obj_num(&self) -> usize {
        return 0;
    }
}
