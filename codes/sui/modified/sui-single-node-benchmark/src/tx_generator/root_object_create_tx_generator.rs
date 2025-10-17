// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::mock_account::Account;
use crate::tx_generator::TxGenerator;
use sui_test_transaction_builder::TestTransactionBuilder;
use sui_types::base_types::{ObjectID, ObjectRef, SuiAddress};
use sui_types::transaction::{CallArg, Transaction, DEFAULT_VALIDATOR_GAS_PRICE};
use std::collections::HashMap;


pub struct RootObjectCreateTxGenerator {
    move_package: ObjectID,
    child_per_root: u64,
}

impl RootObjectCreateTxGenerator {
    pub fn new(move_package: ObjectID, child_per_root: u64) -> Self {
        Self {
            move_package,
            child_per_root,
        }
    }
}

impl TxGenerator for RootObjectCreateTxGenerator {
    fn generate_tx(&self, account: Account, _to:SuiAddress, _args: HashMap<String, usize>, _objects: Vec<ObjectRef>) -> Transaction {
        TestTransactionBuilder::new(
            account.sender,
            account.gas_objects[0],
            DEFAULT_VALIDATOR_GAS_PRICE,
        )
        .move_call(
            self.move_package,
            "benchmark",
            "generate_dynamic_fields",
            vec![CallArg::Pure(bcs::to_bytes(&self.child_per_root).unwrap())],
        )
        .build_and_sign(account.keypair.as_ref())
    }

    fn name(&self) -> &'static str {
        "Root Object Creation Transaction Generator"
    }

    fn shared_obj_num(&self) -> usize {
        return 0;
    }
}
