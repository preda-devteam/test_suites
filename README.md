# Tests Evaluation

We evaluated the widely used smart contracts — MyToken (ERC20), ETH TokenTransfer, Voting, Airdrop, CryptoKitties and MillionPixel — across multiple blockchain systems, including Sei, Aptos, Sui, Crystality (implemented on REVM), and PREDA.

The experiments focused on two key metrics: Transactions Per Second (TPS) and Speedup Ratios, which measure the performance gains achieved through parallel execution compared to each system’s single-VM baseline.

## 1. How Experiments Were Conducted
Here, we will explain the methodology we used to create the benchmark charts below. Specifically, we will detail the data sources, the implementation processes, and the evaluation methods.

| Test Setup             |                                                              |
| :--------------------- | :----------------------------------------------------------- |
| **Hardware Setup**     | The performance comparisons are conducted on a high-performance multi-core machine equipped with two AMD EPYC 7742 CPUs (64-core, 2.25GHz - 3.4GHz max boost) and 2TB of memory, running Linux Ubuntu 20.04. |
| **Software Setup**     | The evaluation above focuses on experiments involving ERC token transfers on Ethereum. Subsequent evaluations in this piece cover a variety of smart contracts, including ETH Transfer, Voting, AirDrop, CryptoKitties, and MillionPixel, all of which were originally deployed and executed on Ethereum.<br/><br/>For Sei, the standard Solidity contracts are used. For Sui and Aptos, equivalent contracts are implemented in Sui Move and Aptos Move languages, respectively. <br/><br/>For the evaluation of PREDA and Crystality, the equivalent contracts are implemented in the PREDA language and the extended Solidity, respectively, with Crystality contracts being transformed into standard Solidity contracts using its source-to-source code transpiler. |
| **Experimental Setup** | The latest open-source code for these five systems is adopted from their  GitHub repositories. Specifically:<br/><br/>Sei: main branch, commit ID 35a7…1972<br/>Aptos: main branch, commit ID a182...7b0b<br/>Sui: testnet branch, commit ID 4dbc...c9a0<br/>Crystality: main branch, commit ID 49e0...d5c8<br/>PREDA: main branch, commit ID 6271...5ef0 |
| **Data Source**        | In Sei, each lightweight Goroutine is managed by its Go runtime. Randomly generated transactions are used for the evaluation of ERC20, Voting, AirDrop, CryptoKitties, and MillionPixel. Specifically, 10,000 addresses and 100,000 transactions are generated for each system. <br><br/>For TokenTransfer, historical ETH transactions are replayed. The historical dataset comprises ETH transfer transactions from January 2024, with batches of 100,000 successive transactions prepared.  <br/><br/>Results are shown for the first batch, including 100,000 transactions from block heights 18,908,895 to 18,910,315 (12:00 am - 04:48 am, UTC, January 01, 2024). After conversion to the proper formats, the dataset is replayed on all five systems, respectively. |
| **Notes**              | In the evaluation, similar system setups are employed for parallel execution, excluding consensus overhead but including other elements like transaction signature verification. All five systems are configured in their single-node benchmark crates, and performance is optimized to the best extent possible. |

For all experiments, transaction volumes remain constant, while the number of parallel VMs varies with the number of CPU cores. In Sui, Aptos, Sei, Crystality and PREDA, each thread is set to a dedicated CPU core.

The experiments compare the throughput performance of all five systems. Considering different programming languages and lower-level virtual machines adopted in the systems, to provide a fair comparison, the experiments also include the relative speedup results (as scalability), calculating the speedup on multiple VMs over each system’s baseline on one VM.

## 2. Benchmarking Crystality-REVM Against Major Parallel Execution Approaches

The results highlight Crystality-REVM’s consistent performance and scalability.

As shown in the figures below, the report presents benchmark results of six representative Solidity contracts tested across 1–64 cores and compared with high-performance chains such as Sui, Aptos, and Sei. Crystality-REVM shows notable scalability, particularly from 32 to 64 cores. In the ERC-20 transfer case, Crystality achieves speedup ratios of 26.9× and 37.1×, outperforming Aptos’ 18.7× and 12.5×, where Aptos’ scalability begins to decline. This demonstrates Crystality’s growing scalability advantage at higher core counts.

### 2.1  ERC20 Token Transfer Contract
**Source Contract:** [**https://solidity-by-example.org/app/erc20/**](https://solidity-by-example.org/app/erc20/)

The ERC20 contract in Solidity is designed for token transfer. It features a contract state *“balanceOf”* representing address balances and a *“transfer”* function to transfer a specified *“amount”* of tokens from the transaction sender *“msg.sender”* to a *“recipient”*. 

The experimental results illustrate the following TPS and relative speedup figures:

![erc20_tps_line](https://github.com/user-attachments/assets/e98147c1-5ab8-4c9e-acc9-bafd18ef7016)
![erc20_speed_up 2](https://github.com/user-attachments/assets/bca2f9f9-8bf0-48fd-a881-65d263a78590)


*TPS and Scalability Breakdown and Comparison*

|                | **TPS over Single Core** | **TPS Maximum over Multiple Cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 486                      | 3,846                               | 7.91x             |
| **Aptos**      | 2,472                    | 46,232                              | 18.70x            |
| **Sui**        | 1,644                    | 22,584                              | 13.73x            |
| **Crystality** | 10,762                   | 399,973                             | 37.17x            |
| **PREDA**      | 8,100                    | 429,184                             | 52.99x            |

### 2.2 ETH TokenTransfer Contract

This experiment was conducted using real historical ETH transactions. The smart contracts used were identical to standard ERC20 smart contracts. 

Both throughput numbers and scalability ratios decreased in Sui, Aptos and Sei systems. This is because repeated addresses in the historical transactions result in contentions (read-write or write-write), hindering the concurrent execution of these transactions in Parallel EVMs.

The experimental results are demonstrated as follows:

![eth_historical_tps_line](https://github.com/user-attachments/assets/9444b817-4ac0-4457-b201-6ed80948d498)
![eth_historical_speed_up 2](https://github.com/user-attachments/assets/f6445461-43fa-45a1-86b6-a44a3ad7b4e8)


*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 350                      | 653                                 | 1.87x             |
| **Aptos**      | 2,459                    | 18,719                              | 7.61x             |
| **Sui**        | 1,558                    | 20,429                              | 13.11x            |
| **Crystality** | 10,784                   | 283,556                             | 26.29x            |
| **PREDA**      | 8,114                    | 255,102                             | 31.44x            |


### 2.3 The Voting Contract

**Source Contract:** https://docs.soliditylang.org/en/latest/solidity-by-example.html

The voting contract serves to gather voting results for proposal candidates. Originally, the algorithm implemented in Solidity is sequential, with users sharing a single array for voting results. An efficient parallel algorithm involves preparing a temporary array on each execution unit (VM). Users can then vote concurrently at different VMs, with the final result being aggregated from these temporary arrays.

The Sei contract follows sequential algorithm, resulting in no speedup when running multiple EVMs. If the algorithm is not transformed to the parallel one, similar results will occur in other systems. For Aptos and Sui, the parallel implementations must initialize multiple resources at different addresses for temporary results of the “proposal” variable. Additionally, the parallel implementations must provide manual scheduling, based on voters' addresses, to direct voters’ transactions to different virtual machines and access temporary results for parallel execution.

For Crystality and PREDA, the parallel implementation is much simpler. It only needs to use the scope keywords of the PREDA model when declaring “proposal” and its temporary variables. The voter-initiated transactions are automatically directed to corresponding virtual machines and executed by those virtual machines concurrently.

The Voting smart contract demonstrates how the PREDA model can simplify the expression of the parallel voting algorithm and how the data partitioning, relay, and execution mechanisms in Crystality and PREDA can avoid the overhead in the optimistic parallelization method (Aptos) and pessimistic parallelization method (Sui) in both TPS numbers and relative speedups.

![ballot_tps_line](https://github.com/user-attachments/assets/56eecb18-cea5-4ceb-ab10-cc1cb03841ae)
![ballot_speed_up 2](https://github.com/user-attachments/assets/9fc31937-d323-4248-a60f-f75e2523b2c1)

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 400                      | 399                                 | 1.0x              |
| **Aptos**      | 3,874                    | 42,087                              | 10.86x            |
| **Sui**        | 1,352                    | 17,319                              | 12.8x             |
| **Crystality** | 14,294                   | 704,059                             | 49.26x            |
| **PREDA**      | 8,385                    | 463,111                             | 55.23x            |

### 2.4 AirDrop 

**Source Contract:** https://github.com/SpringRole/smart-contracts/blob/master/contracts/AirDrop.sol

AirDrop is a widely used smart contract where a user-initiated transaction will trigger multiple token or NFT transfers from one address to multiple addresses. Compared to the ERC20 and Voting smart contracts, involving one-to-one and multiple-to-one state changes respectively, the AirDrop smart contract has a one-to-multiple state change mode.

If the sender address or one destination address is involved in two AirDrop transactions, these two transactions cannot be executed concurrently in Sei, Aptos, or Sui. For example, Txn A involves an AirDrop from address 0 to states 1 and 2, and Txn B involves an AirDrop from address 0 to states 3 and 4. Txns A and B must be executed sequentially.

In contrast, in the PREDA model, since the parallel granularity is broken down into each state access, both Crystality and PREDA can parallelize these two transactions in a pipeline mode. Txn A is decomposed into three steps: accessing states 0, 1, and 2; and Txn B is decomposed into accessing states 0, 3, and 4. Once accessing state 0 in Txn A and Txn B are completed sequentially, accessing states 1, 2, 3, and 4 can be executed by different virtual machines concurrently.

The experimental results illustrate the following TPS and relative speedup figures:

![AirDrop_Tps](https://github.com/user-attachments/assets/c24c9e62-b3ae-4343-a026-4e4c05989d86)
![AirDrop_Speedup](https://github.com/user-attachments/assets/95fd1cf8-4b1c-4bec-b10e-e3147b5f33dd)


*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 362                      | 922                                 | 2.55x             |
| **Aptos**      | 2,840                    | 55,309                              | 19.48x            |
| **Sui**        | 1,007                    | 15,513                              | 15.41x            |
| **Crystality** | 4,234                    | 141,970                             | 33.53x            |
| **PREDA**      | 7,002                    | 222,222                             | 31.74x            |

### 2.5 CryptoKitties

**Source Contract:** https://gist.github.com/arpit/071e54b95a81d13cb29681407680794f

This contract, a popular game contract on Ethereum, involves breeding digital cats based on genes from parent cats. Different from the previous ones, this contract needs to access multiple address states when processing a user-initiated transaction, including a “sire kitty”, a “matron kitty”, and a “newborn kitty”. This contract also involves more complicated computations than the previous ones when calculating the newborn’s gene from the parents’ genes.

The experimental results illustrate the following TPS and relative speedup figures:

![kitty_tps_line](https://github.com/user-attachments/assets/82498d78-0cdb-4cde-8b34-e5841f908155)
![kitty_speed_up 2](https://github.com/user-attachments/assets/0da76059-b658-4872-ba9e-7bd22c07df41)

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 238                      | 262                                 | 1.10x             |
| **Aptos**      | 766                      | 2,475                               | 3.23x             |
| **Sui**        | 451                      | 9,150                               | 20.29x            |
| **Crystality** | 1,370                    | 77,662                              | 56.69x            |
| **PREDA**      | 6,161                    | 200,000                             | 32.46x            |

### 2.6 MillionPixel Contract

**Source Contract:** https://millionpixeldfi.github.io/

In this game contract on Ethereum, users compete to mark coordinates on a map. This smart contract is used to illustrate the flexibility of the PREDA model and Crystality. Other than partitioning contract states by address, programmers can customize the partitioning key, e.g., from address type to uint32 type in this case.

![million_pixel_tps_line](https://github.com/user-attachments/assets/de09f85a-5f0d-484b-8ac1-a7bd7b1031ed)
![million_pixel_speed_up 2](https://github.com/user-attachments/assets/386924c9-87fe-48c3-8c4a-6142adb004a2)


*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 496                      | 5,851                               | 11.80x            |
| **Aptos**      | 3,653                    | 54,347                              | 14.88x            |
| **Sui**        | 1,027                    | 15,335                              | 14.93x            |
| **Crystality** | 17,632                   | 678,877                             | 38.50x            |
| **PREDA**      | 8,133                    | 420,302                             | 51.68x            |
