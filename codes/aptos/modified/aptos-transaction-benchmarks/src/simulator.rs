// Copyright © Aptos Foundation
// SPDX-License-Identifier: Apache-2.0

use crate::transactions::RAYON_EXEC_POOL;
use aptos_block_executor::txn_commit_hook::NoOpTransactionCommitHook;

use aptos_language_e2e_tests::{
    account_universe::{AccountPickStyle, AccountUniverse, AccountUniverseGen}, 
    common_transactions::{
        airdrop_initialize_txn,
        airdrop_transfer_txn,
        ballot_initialize_txn,
        ballot_vote_txn,
        million_pixel_initialize_txn,
        million_pixel_occupy_txn,
        kitty_initialize_txn,
        kitty_mint_txn,
        kitty_breed_txn,
        empty_empty_txn,
        peer_to_peer_txn
    }, 
    data_store::FakeDataStore, executor::FakeExecutor
};
use aptos_types::{
    block_executor::config::BlockExecutorConfig,
    transaction::{
        signature_verified_transaction::{
            into_signature_verified_block, SignatureVerifiedTransaction,
        }, ExecutionStatus, SignedTransaction, Transaction, TransactionOutput, TransactionStatus
    },
    vm_status::VMStatus,
};
use aptos_vm::block_executor::{AptosTransactionOutput, BlockAptosVM};
use proptest::{prelude::Strategy, strategy::ValueTree, test_runner::TestRunner};
use std::{ collections::HashMap, sync::Arc, time::Instant};
use rand::Rng;

macro_rules! print_tps {
    ($par_tps:expr,$seq_tps:expr) => {
        println!("Parallel TPS: {}", $par_tps);
        println!("Sequential TPS: {}", $seq_tps);
        println!("Speed up {:.2}x over sequential", $par_tps as f64 / $seq_tps as f64);
    };
}

pub struct Similator{
    account_universe: AccountUniverse,
    state_view: Arc<FakeDataStore>,
}

//for experiment
impl Similator{
    //new Simulator with a account set
    pub fn with_account_nums(
        num_accounts:usize,
    ) -> Self {
        let mut runner = TestRunner::default();
        let balance = 500_000 * 1_000_000 * 5 as u64;
        let universe_strategy = AccountUniverseGen::strategy(num_accounts, balance..(balance + 1), AccountPickStyle::Unlimited);

        let universe_gen = universe_strategy
            .new_tree(&mut runner)
            .expect("creating a new value should succeed")
            .current();
        let mut executor = FakeExecutor::from_head_genesis();
        
        let universe = universe_gen.setup_gas_cost_stability(&mut executor);

        let state_view = Arc::new(executor.get_state_view().clone());

        Self {
            account_universe: universe,
            state_view,
        }
    }

    pub fn gen_transaction_for_erc20(&mut self,transaction_graph:Vec<(usize,usize)>) -> Vec<SignatureVerifiedTransaction> {
        let mut account_num_max = 0;
        let mut seq_map: HashMap<usize, usize> = HashMap::new();
        let mut signed_transactions = Vec::new();
        for tuple in &transaction_graph{
            account_num_max = account_num_max.max(tuple.0).max(tuple.1);
            let sender = self.account_universe.account(tuple.0);
            let receiver = self.account_universe.account(tuple.1);
            let entry = seq_map.entry(tuple.0);
            match entry {
                std::collections::hash_map::Entry::Occupied(mut occupied)=>{
                    *occupied.get_mut()+=1;
                }
                std::collections::hash_map::Entry::Vacant(vacant) => {
                    vacant.insert(sender.sequence_number() as usize);
                }
            };
            let txn = peer_to_peer_txn(
                sender.account(), 
                receiver.account(), 
                seq_map[&tuple.0] as u64, 
                1,
                100
            );
            // println!("gen txn: {:?} to {:?} :{}",sender.account().address(),receiver.account().address(),1);
            signed_transactions.push(txn);   
        }
        let transactions: Vec<Transaction> = signed_transactions
            .into_iter()
            .map(|txn| {
                Transaction::UserTransaction(txn)
            })
            .collect();
        into_signature_verified_block(transactions)       
    }

    fn execute_and_apply_transactions(
        &mut self,
        signed_transactions:Vec<SignedTransaction>,
    ){
        let signature_verified_transactions = into_signature_verified_block(
            signed_transactions
            .into_iter()
            .map(|txn| {
                Transaction::UserTransaction(txn)
            })
            .collect()
        );
        let output = BlockAptosVM::execute_block::<
            _,
            NoOpTransactionCommitHook<AptosTransactionOutput, VMStatus>,
        >(
            Arc::clone(&RAYON_EXEC_POOL),
            &signature_verified_transactions,
            self.state_view.as_ref(),
            BlockExecutorConfig::new_maybe_block_limit(
                num_cpus::get(),
                None,
            ),
            None,
        )
        .expect("VM should not fail to start")
        .into_transaction_outputs_forced();
        output.iter().for_each(|txn_output| {
            assert_eq!(
                txn_output.status(),
                &TransactionStatus::Keep(ExecutionStatus::Success)
            );
            Arc::make_mut(&mut self.state_view).add_write_set(txn_output.write_set());
        });
    }

    fn execute_benchmark_sequential(
        &self,
        transactions: &[SignatureVerifiedTransaction],
        maybe_block_gas_limit: Option<u64>,
    ) -> (Vec<TransactionOutput>, usize) {
        let block_size = transactions.len();
        let timer = Instant::now();
        let output = BlockAptosVM::execute_block::<
            _,
            NoOpTransactionCommitHook<AptosTransactionOutput, VMStatus>,
        >(
            Arc::clone(&RAYON_EXEC_POOL),
            transactions,
            self.state_view.as_ref(),
            BlockExecutorConfig::new_maybe_block_limit(1, maybe_block_gas_limit),
            None,
        )
        .expect("VM should not fail to start")
        .into_transaction_outputs_forced();
        let exec_time = timer.elapsed().as_millis();
        println!("exec total: {} ", timer.elapsed().as_nanos());
        (output, block_size * 1000 / exec_time as usize)
    }

    fn execute_benchmark_parallel(
        &self,
        transactions: &[SignatureVerifiedTransaction],
        concurrency_level_per_shard: usize,
        maybe_block_gas_limit: Option<u64>,
    ) -> (Vec<TransactionOutput>, usize) {
        let block_size = transactions.len();
        let timer = Instant::now();
        let output = BlockAptosVM::execute_block::<
            _,
            NoOpTransactionCommitHook<AptosTransactionOutput, VMStatus>,
        >(
            Arc::clone(&RAYON_EXEC_POOL),
            transactions,
            self.state_view.as_ref(),
            BlockExecutorConfig::new_maybe_block_limit(
                concurrency_level_per_shard,
                maybe_block_gas_limit,
            ),
            None,
        )
        .expect("VM should not fail to start")
        .into_transaction_outputs_forced();
        let exec_time = timer.elapsed().as_millis();
        println!("exec total: {} ", timer.elapsed().as_nanos());
        (output, block_size * 1000 / exec_time as usize)
    }

    pub fn execute_blockstm_benchmark(
        &mut self,
        transactions: Vec<SignatureVerifiedTransaction>,
        run_par: bool,
        run_seq: bool,
        concurrency_level_per_shard: usize,
        maybe_block_gas_limit: Option<u64>,
    ) -> (usize, usize) {
        let (output, par_tps) = if run_par {
            println!("Parallel execution starts...");
            let (output, tps) =
                self.execute_benchmark_parallel(
                    &transactions, 
                    concurrency_level_per_shard,
                    maybe_block_gas_limit
                );
            println!("Parallel execution finishes, TPS = {}", tps);
            (output, tps)
        }else{
            (vec![],0)
        };
        output.iter().for_each(|txn_output| {
            assert_eq!(
                txn_output.status(),
                &TransactionStatus::Keep(ExecutionStatus::Success)
            );
        });
        let (output, seq_tps) = if run_seq {
            println!("Sequential execution starts...");
            let (output, tps) =
                self.execute_benchmark_sequential(&transactions, maybe_block_gas_limit);
            println!("Sequential execution finishes, TPS = {}", tps);
            (output, tps)
        } else {
            (vec![], 0)
        };
        output.iter().for_each(|txn_output| {
            assert_eq!(
                txn_output.status(),
                &TransactionStatus::Keep(ExecutionStatus::Success)
            );
        });
        (par_tps, seq_tps)
    }

    pub fn run_airdrop(&mut self, transaction_nums: usize){
        //initialize accounts
        let mut initilazied_transactions = Vec::new();
        {
            for i in 0..self.account_universe.num_accounts(){
                let sender = self.account_universe.account_mut(i as usize);
                let txn = airdrop_initialize_txn(
                    sender.account(), 
                    1_000_000_000, 
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                initilazied_transactions.push(txn);
            }
        }
        self.execute_and_apply_transactions(initilazied_transactions);
        
        //execute airdrop transfer
        println!("execute transfer for airdrop...");
        let mut transfer_transactions = Vec::new();
        let acc_nums = self.account_universe.num_accounts();
        {
            let mut rng = rand::thread_rng();
            for _i in 0..transaction_nums{
                let random_number: usize = rng.gen_range(0, acc_nums);
                let mut receivers = Vec::new();
                for _j in 0..5{
                    let random_number = rng.gen_range(0, acc_nums);
                    let &receiver = self.account_universe.account_mut(random_number as usize).account().address();
                    receivers.push(receiver);
                }
                let sender = self.account_universe.account_mut(random_number);
                let txn = airdrop_transfer_txn(
                    sender.account(),
                    receivers,
                    sender.sequence_number(),
                    100,
                );
                sender.increase_account_sequence_number();
                transfer_transactions.push(txn);
            }
        }
        let (par_tps, seq_tps) = self.execute_blockstm_benchmark(
            into_signature_verified_block(
                transfer_transactions
                    .into_iter()
                    .map(|txn|{
                        Transaction::UserTransaction(txn)
                    })
                    .collect()
            ), 
            true, 
            true, 
            num_cpus::get(), 
            None
        );
        print_tps!(par_tps,seq_tps);
    }

    pub fn run_ballot(&mut self, transaction_num:usize){
        let acc_nums = self.account_universe.num_accounts();
        let mut initilazied_transactions = Vec::new();
        {
            let (forums,_accounts) = self.account_universe.accounts_mut().split_at_mut(1);
            //initialize transaction for ballot
            let proposals:Vec<Vec<u8>> = vec!["aa".to_string(),"bb".to_string(),"cc".to_string()].into_iter().map(|s| s.into_bytes()).collect();
            let txn = ballot_initialize_txn(
                forums[0].account(), 
                proposals, 
                forums[0].sequence_number(), 
                100
            );
            forums[0].increase_account_sequence_number();
            initilazied_transactions.push(txn);
        }
        self.execute_and_apply_transactions(initilazied_transactions);
        
        //vote
        println!("execute vote for ballot...");
        let mut vote_transactions = Vec::new();
        {
            let mut rng = rand::thread_rng();
            let (forums,accounts) = self.account_universe.accounts_mut().split_at_mut(1);
            for _i in 0..transaction_num{
                let proposal_index = rng.gen_range(0, 3);
                let sender_index = rng.gen_range(0, acc_nums-1);
                let sender = &mut accounts[sender_index];
                let txn = ballot_vote_txn(
                    sender.account(),
                    forums[0].account().address(), 
                    proposal_index, 
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                vote_transactions.push(txn);
            }
        }
        let (par_tps, seq_tps) = self.execute_blockstm_benchmark(
            into_signature_verified_block(
                vote_transactions
                        .into_iter()
                        .map(|txn|{
                            Transaction::UserTransaction(txn)
                        })
                        .collect()
            ), 
            true, 
            true, 
            num_cpus::get(), 
            None
        );
        print_tps!(par_tps,seq_tps);
    }

    pub fn run_ballot_sharding(&mut self, transaction_num:usize,shard_num:usize){
        let acc_nums = self.account_universe.num_accounts();
        let mut initilazied_transactions = Vec::new();
        {
            let (forums,_accounts) = self.account_universe.accounts_mut().split_at_mut(shard_num);
            //initialize transaction for ballot
            for i in 0..shard_num{
                let proposals:Vec<Vec<u8>> = vec!["aa".to_string(),"bb".to_string(),"cc".to_string()].into_iter().map(|s| s.into_bytes()).collect();
                let txn = ballot_initialize_txn(
                    forums[i].account(), 
                    proposals, 
                    forums[i].sequence_number(), 
                    100
                );
                forums[i].increase_account_sequence_number();
                initilazied_transactions.push(txn);
            }
        }
        self.execute_and_apply_transactions(initilazied_transactions);
        
        //vote
        println!("execute vote for ballot...");
        let mut vote_transactions = Vec::new();
        {
            let mut rng = rand::thread_rng();
            let (forums,accounts) = self.account_universe.accounts_mut().split_at_mut(shard_num);
            for _i in 0..transaction_num{
                let proposal_index = rng.gen_range(0, 3);
                let sender_index = rng.gen_range(0, acc_nums-shard_num);
                let sender = &mut accounts[sender_index];
                let forums_index = sender.account().address().to_vec()[31] % shard_num as u8;
                let txn = ballot_vote_txn(
                    sender.account(),
                    forums[forums_index as usize].account().address(), 
                    proposal_index, 
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                vote_transactions.push(txn);
            }
        }
        let (par_tps, seq_tps) = self.execute_blockstm_benchmark(
            into_signature_verified_block(
                vote_transactions
                        .into_iter()
                        .map(|txn|{
                            Transaction::UserTransaction(txn)
                        })
                        .collect()
            ), 
            true, 
            true, 
            num_cpus::get(), 
            None
        );
        print_tps!(par_tps,seq_tps);
    }

    pub fn run_mp(&mut self, transaction_num:usize){
        
        let mut initilazied_transactions = Vec::new();
        {
            let (globalstore,_accounts) = self.account_universe.accounts_mut().split_at_mut(1);
            //initialize transaction for mp
            let txn = million_pixel_initialize_txn(
                globalstore[0].account(), 
                globalstore[0].sequence_number(), 
                100
            );
            globalstore[0].increase_account_sequence_number();
            initilazied_transactions.push(txn);
        }
        self.execute_and_apply_transactions(initilazied_transactions);
        
        //occupy
        println!("execute occupy for million_pixel...");
        let mut occupy_transactions = Vec::new();
        {
            let mut rng = rand::thread_rng();
            let (globalstore,accounts) = self.account_universe.accounts_mut().split_at_mut(1);
            let acc_nums = accounts.len();
            for _i in 0..transaction_num{    
                let x = rng.gen_range(0, 100);
                let y  = rng.gen_range(0,100);
                let sender_index = rng.gen_range(0, acc_nums);
                let sender = &mut accounts[sender_index];
                let txn = million_pixel_occupy_txn(
                    sender.account(),
                    globalstore[0].account().address(), 
                    x, 
                    y,
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                occupy_transactions.push(txn);
            }
        }
        let (par_tps, seq_tps) = self.execute_blockstm_benchmark(
            into_signature_verified_block(
                occupy_transactions
                        .into_iter()
                        .map(|txn|{
                            Transaction::UserTransaction(txn)
                        })
                        .collect()
            ), 
            true, 
            true, 
            num_cpus::get(), 
            None
        );
        print_tps!(par_tps,seq_tps);
    }

    pub fn run_kitty(&mut self, transaction_num:usize){
        let mut initilazied_transactions = Vec::new();
        {
            let (globalstore,accounts) = self.account_universe.accounts_mut().split_at_mut(1);
            let acc_nums = accounts.len();
            //initialize transaction for kitty
            let txn = kitty_initialize_txn(
                globalstore[0].account(), 
                globalstore[0].sequence_number(), 
                100
            );
            globalstore[0].increase_account_sequence_number();
            initilazied_transactions.push(txn);
            let mut rng = rand::thread_rng();
            for i in 0..acc_nums{
                let sender = &mut accounts[i];
                                let txn = kitty_mint_txn(
                    sender.account(), 
                    globalstore[0].account().address(), 
                    rng.gen_range(0, (1<<32)-1), 
                    true, 
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                initilazied_transactions.push(txn);
            }

            for i in 0..acc_nums{
                let sender = &mut accounts[i];
                let txn = kitty_mint_txn(
                    sender.account(), 
                    globalstore[0].account().address(), 
                    rng.gen_range(0, (1<<32)-1), 
                    false, 
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                initilazied_transactions.push(txn);
            }
            
        }
        self.execute_and_apply_transactions(initilazied_transactions);
        
        //breed
        println!("execute breed for kitty...");
        let mut breed_transactions = Vec::new();
        {
            let mut rng = rand::thread_rng();
            let (globalstore,accounts) = self.account_universe.accounts_mut().split_at_mut(1);
            let acc_nums = accounts.len();
            for _i in 0..transaction_num{
                let m = rng.gen_range(0, acc_nums) as u64;
                let s  = rng.gen_range(acc_nums,acc_nums*2) as u64;
                let sender_index = rng.gen_range(0, acc_nums);
                let sender = &mut accounts[sender_index];
                let txn = kitty_breed_txn(
                    sender.account(),
                    globalstore[0].account().address(), 
                    m,
                    s,
                    false,
                    sender.sequence_number(), 
                    100
                );
                sender.increase_account_sequence_number();
                breed_transactions.push(txn);
            }
        }
        let (par_tps, seq_tps) = self.execute_blockstm_benchmark(
            into_signature_verified_block(
                breed_transactions
                        .into_iter()
                        .map(|txn|{
                            Transaction::UserTransaction(txn)
                        })
                        .collect()
            ), 
            true, 
            true, 
            num_cpus::get(), 
            None
        );
        print_tps!(par_tps,seq_tps);

    }


    pub fn run_empty(&mut self,transaction_nums:usize){
        //execute airdrop transfer
        println!("execute empty...");
        let mut empty_transactions = Vec::new();
        let mut rng = rand::thread_rng();
        let acc_nums = self.account_universe.num_accounts();
        for _i in 0..transaction_nums{
            let random_number: usize = rng.gen_range(0, acc_nums);
            let sender = self.account_universe.account_mut(random_number);
            let txn = empty_empty_txn(sender.account(), sender.sequence_number(),100);
            sender.increase_account_sequence_number();
            empty_transactions.push(txn);
        }
        let (par_tps, seq_tps) = self.execute_blockstm_benchmark(
            into_signature_verified_block(
                empty_transactions
                    .into_iter()
                    .map(|txn|{
                        Transaction::UserTransaction(txn)
                    })
                    .collect()
            ), 
            true, 
            true, 
            num_cpus::get(), 
            None
        );
        print_tps!(par_tps,seq_tps);
    }
}
