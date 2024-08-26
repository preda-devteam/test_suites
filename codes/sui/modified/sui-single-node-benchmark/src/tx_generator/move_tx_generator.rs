// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::mock_account::Account;
use crate::tx_generator::TxGenerator;
use move_core_types::identifier::Identifier;
use std::collections::HashMap;
use sui_test_transaction_builder::TestTransactionBuilder;
use sui_types::base_types::{ObjectID, ObjectRef, SequenceNumber, SuiAddress};
use sui_types::programmable_transaction_builder::ProgrammableTransactionBuilder;
use sui_types::transaction::{CallArg, ObjectArg, Transaction, DEFAULT_VALIDATOR_GAS_PRICE};
use rand::Rng;

pub struct MoveTxGenerator {
    move_package: ObjectID,
    num_transfers: u64,
    use_native_transfer: bool,
    computation: u8,
    root_objects: HashMap<SuiAddress, ObjectRef>,
    shared_objects: Vec<(ObjectID, SequenceNumber)>,
    erc20_transfer: bool,
    kitty_objects: HashMap<SuiAddress, ObjectRef>,
    land_objects: HashMap<u16, (ObjectID, SequenceNumber)>,
}

impl MoveTxGenerator {
    pub fn new(
        move_package: ObjectID,
        num_transfers: u64,
        use_native_transfer: bool,
        computation: u8,
        root_objects: HashMap<SuiAddress, ObjectRef>,
        shared_objects: Vec<(ObjectID, SequenceNumber)>,
        erc20_transfer: bool,
        kitty_objects: HashMap<SuiAddress, ObjectRef>,
        land_objects: HashMap<u16, (ObjectID, SequenceNumber)>,
    ) -> Self {
        Self {
            move_package,
            num_transfers,
            use_native_transfer,
            computation,
            root_objects,
            shared_objects,
            erc20_transfer,
            kitty_objects,
            land_objects,
        }
    }
}

impl TxGenerator for MoveTxGenerator {
    fn generate_tx(&self, account: Account, to:SuiAddress, args: HashMap<String, usize>, objects: Vec<ObjectRef>) -> Transaction {
        let pt = {
            let mut builder = ProgrammableTransactionBuilder::new();
            // Step 1: transfer `num_transfers` objects.
            // First object in the gas_objects is the gas object and we are not transferring it.
            for i in 1..=self.num_transfers {
                let object = account.gas_objects[i as usize];
                if self.use_native_transfer {
                    builder.transfer_object(account.sender, object).unwrap();
                } else {
                    builder
                        .move_call(
                            self.move_package,
                            Identifier::new("benchmark").unwrap(),
                            Identifier::new("transfer_coin").unwrap(),
                            vec![],
                            vec![CallArg::Object(ObjectArg::ImmOrOwnedObject(object))],
                        )
                        .unwrap();
                }
            }
            if self.shared_objects.len() > 0 {
                let shared_obj_index = args.get(&String::from("shared_obj_index")).copied().unwrap_or(0);
                builder
                    .move_call(
                        self.move_package,
                        Identifier::new("benchmark").unwrap(),
                        Identifier::new("increment_shared_counter").unwrap(),
                        vec![],
                        vec![CallArg::Object(ObjectArg::SharedObject {
                            id: self.shared_objects[shared_obj_index].0,
                            initial_shared_version: self.shared_objects[shared_obj_index].1,
                            mutable: true,
                        })],
                    )
                    .unwrap();
            }

            if !self.root_objects.is_empty() {
                // Step 2: Read all dynamic fields from the root object.
                let root_object = self.root_objects.get(&account.sender).unwrap();
                let root_object_arg = builder
                    .obj(ObjectArg::ImmOrOwnedObject(*root_object))
                    .unwrap();
                builder.programmable_move_call(
                    self.move_package,
                    Identifier::new("benchmark").unwrap(),
                    Identifier::new("read_dynamic_fields").unwrap(),
                    vec![],
                    vec![root_object_arg],
                );
            }

            if self.computation > 0 {
                // Step 3: Run some computation.
                let computation_arg = builder.pure(self.computation as u64 * 100).unwrap();
                builder.programmable_move_call(
                    self.move_package,
                    Identifier::new("benchmark").unwrap(),
                    Identifier::new("run_computation").unwrap(),
                    vec![],
                    vec![computation_arg],
                );
            }
            if self.erc20_transfer {
                let obj_index = args.get(&String::from("obj_index")).copied().unwrap_or(0);
                let gas_num = account.gas_objects.len();
                let object = account.gas_objects[gas_num / 2 + obj_index];
                
                // let amount:u64 = 1;
                builder
                    .move_call(
                        self.move_package,
                        Identifier::new("benchmark").unwrap(),
                        Identifier::new("transfer_coin").unwrap(),
                        vec![],
                        vec![CallArg::Object(ObjectArg::ImmOrOwnedObject(object))],
                    )
                    .unwrap();
            }
            if self.kitty_objects.len() > 0 {
                let kitty_object = self.kitty_objects.get(&account.sender).unwrap();
                let kitty_fn_index = args.get(&String::from("kitty_fn")).copied().unwrap_or(0);

                if kitty_fn_index == 1 {
                    builder.move_call(
                        self.move_package,
                        Identifier::new("KittyBreeding").unwrap(),
                        Identifier::new("provide_gene").unwrap(),
                        vec![],
                        vec![CallArg::Object(ObjectArg::ImmOrOwnedObject(*kitty_object)), CallArg::Pure(bcs::to_bytes(&to).unwrap())],
                    )
                    .unwrap();
                } else {
                    let gene_object = objects[0];
                    let new_kitty_object = objects[1];
                    builder.move_call(
                        self.move_package,
                        Identifier::new("KittyBreeding").unwrap(),
                        Identifier::new("breed").unwrap(),
                        vec![],
                        vec![CallArg::Object(ObjectArg::ImmOrOwnedObject(gene_object)), CallArg::Object(ObjectArg::ImmOrOwnedObject(new_kitty_object))],
                    )
                    .unwrap();
                }
            }
            if self.land_objects.len() > 0 {
                let len = self.land_objects.len() as u16;
                let mut rng = rand::thread_rng();
                let x: u16 = rng.gen();
                let y: u16 = rng.gen();
                let key = (x as u32) * 65536 + (y as u32);
                let index = (key % (len as u32)) as u16;
                let land_object = self.land_objects.get(&index).unwrap();
                // println!("occupy x:{}, y:{}, land:{}", x, y, land_object.0);
                builder
                    .move_call(
                        self.move_package,
                        Identifier::new("MillionPixel").unwrap(),
                        Identifier::new("occupy").unwrap(),
                        vec![],
                        vec![CallArg::Object(ObjectArg::SharedObject {
                            id: land_object.0,
                            initial_shared_version: land_object.1,
                            mutable: true,
                        }), CallArg::Pure(bcs::to_bytes(&x).unwrap()), CallArg::Pure(bcs::to_bytes(&y).unwrap())],
                    )
                    .unwrap();
            }
            
            builder.finish()
        };
        let obj_index = args.get(&String::from("obj_index")).copied().unwrap_or(0);
        TestTransactionBuilder::new(
            account.sender,
            account.gas_objects[obj_index],
            DEFAULT_VALIDATOR_GAS_PRICE,
        )
        .programmable(pt)
        .build_and_sign(account.keypair.as_ref())
    }

    fn name(&self) -> &'static str {
        "Programmable Move Transaction Generator"
    }

    fn shared_obj_num(&self) -> usize {
        return self.shared_objects.len();
    }
}
