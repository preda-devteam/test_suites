// Copyright © Aptos Foundation
// Parts of the project are originally copyright © Meta Platforms, Inc.
// SPDX-License-Identifier: Apache-2.0

//! Support for encoding transactions for common situations.

use crate::account::Account;
use aptos_cached_packages::aptos_stdlib;
use aptos_types::transaction::{Script, SignedTransaction};
use move_ir_compiler::Compiler;
use once_cell::sync::Lazy;
use move_core_types::account_address::AccountAddress;

pub static EMPTY_SCRIPT: Lazy<Vec<u8>> = Lazy::new(|| {
    let code = "
    main(account: signer) {
    label b0:
      return;
    }
";
    let modules = aptos_cached_packages::head_release_bundle().compiled_modules();
    let compiler = Compiler {
        deps: modules.iter().collect(),
    };
    compiler.into_script_blob(code).expect("Failed to compile")
});

pub fn empty_txn(
    sender: &Account,
    seq_num: u64,
    max_gas_amount: u64,
    gas_unit_price: u64,
) -> SignedTransaction {
    sender
        .transaction()
        .script(Script::new(EMPTY_SCRIPT.to_vec(), vec![], vec![]))
        .sequence_number(seq_num)
        .max_gas_amount(max_gas_amount)
        .gas_unit_price(gas_unit_price)
        .sign()
}

/// Returns a transaction to create a new account with the given arguments.
pub fn create_account_txn(
    sender: &Account,
    new_account: &Account,
    seq_num: u64,
) -> SignedTransaction {
    sender
        .transaction()
        .payload(aptos_stdlib::aptos_account_create_account(
            *new_account.address(),
        ))
        .sequence_number(seq_num)
        .sign()
}

/// Returns a transaction to transfer coin from one account to another (possibly new) one,
/// with the given arguments. Providing 0 as gas_unit_price generates transactions that
/// don't use an aggregator for total supply tracking (due to logic in coin.move that
/// doesn't generate a delta for total supply when gas is 0).
pub fn peer_to_peer_txn(
    sender: &Account,
    receiver: &Account,
    seq_num: u64,
    transfer_amount: u64,
    gas_unit_price: u64,
) -> SignedTransaction {
    // get a SignedTransaction
    sender
        .transaction()
        .payload(aptos_stdlib::aptos_coin_transfer(
            *receiver.address(),
            transfer_amount,
        ))
        .sequence_number(seq_num)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call airdrop initialize
pub fn airdrop_initialize_txn(
    sender:&Account,
    amount:u64,
    seq_num: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_airdrop_initialize(amount))
        .sequence_number(seq_num)
        .gas_unit_price(gas_unit_price)
        .sign()
}

// call airdrop transfer_n
pub fn airdrop_transfer_txn(
    sender:&Account,
    receiver:Vec<AccountAddress>,
    seq_num: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_airdrop_transfer_n(receiver))
        .sequence_number(seq_num)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call ballot initialize
pub fn ballot_initialize_txn(
    sender:&Account,
    names: Vec<Vec<u8>>,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_ballot_initialize(names))
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call ballot vote
pub fn ballot_vote_txn(
    sender: &Account,
    forum: &AccountAddress,
    proposal_index: u64,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_ballot_vote(
            *forum, 
            proposal_index
        ))
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call million_pixel initialize
pub fn million_pixel_initialize_txn(
    sender:&Account,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_million_pixel_initialize())
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call million_pixel occupy
pub fn million_pixel_occupy_txn(
    sender:&Account,
    globalstore:&AccountAddress,
    x:u16,
    y:u16,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_million_pixel_occupy(
            *globalstore,
            x,
            y
        ))
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call kitty initialize
pub fn kitty_initialize_txn(
    sender:&Account,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_kitty_breeding_initialize())
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call kitty mint
pub fn kitty_mint_txn(
    sender:&Account,
    globalstore:&AccountAddress,
    genes:u64,
    gender:bool,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_kitty_breeding_mint(
            *globalstore,
            genes,
            gender
        ))
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call kitty breed
pub fn kitty_breed_txn(
    sender:&Account,
    globalstore:&AccountAddress,
    m:u64,
    s:u64,
    gender:bool,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_kitty_breeding_breed(
            *globalstore,
            m,
            s,
            gender
        ))
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}

//call emtpy
pub fn empty_empty_txn(
    sender:&Account,
    sequence_number: u64,
    gas_unit_price: u64,
) ->SignedTransaction{
    sender
        .transaction()
        .payload(aptos_stdlib::xtl_empty_empty())
        .sequence_number(sequence_number)
        .gas_unit_price(gas_unit_price)
        .sign()
}