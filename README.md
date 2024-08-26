# Test Suites

**Aptos** 

> **repo**:  https://github.com/aptos-labs/aptos-core.git
>
> **branch**: main
>
> **commitid**:a1822a

**Sui**

> **repo**: https://github.com/MystenLabs/sui
>
> **branch**:testnet
>
> **commitid**:4dbcf8

**Preda**

> **repo**: https://github.com/preda-devteam/preda.git
>
> **branch**:main

**Sei**

> **repo**: https://github.com/sei-protocol/sei-chain.git
>
> **branch**:main
>
> **commitid**:867aae


## Dependency

This code repository has the following open-source software dependencies, as listed below

### Install all dependencies

```shell
#download dependencies from apt-get
sudo apt install libssl-dev python3-pip cmake llvm lld clang 
#download rust from rustup
curl https://sh.rustup.rs -sSf | sh
```

here are individual dependencies

**openssl**

```shell
sudo apt install libssl-dev
```

**pip3**

```shell
sudo apt install python3-pip
```

**cmake**

```shell
sudo apt install cmake
```

**llvm**

```shell
sudo apt install llvm
```

**lld**

```shell
sudo apt install lld
```

**Preda Dependencies**

```shell
sudo apt install p7zip-full pkg-config cmake libx11-dev uuid-dev libgflags-dev libsnappy-dev zlib1g-dev libbz2-dev liblz4-dev libzstd-dev g++-9 gcc-9
```

**clang**

```shell
sudo apt install clang
```

**Rust env**

```shell
#download rust from rustup
$ curl https://sh.rustup.rs -sSf | sh
```

**Go env**

```shell
#download rust from rustup
$ sudo apt install go
```


## Usage

```shell
cd test-suites/scripts

chmod +x setup.sh run_benchmark.sh

#download aptos/sui/preda/sei repos and replaces some files for performance comparison
./setup.sh [option]

#after the previous successful step
#run all test case
./run_benchmark.sh all

#or you can run specific test case
./run_benchmark.sh airdrop
./run_benchmark.sh ballot
./run_benchmark.sh erc20
./run_benchmark.sh replay
./run_benchmark.sh kitty
./run_benchmark.sh million_pixel

#profile data will be in test-suites/results
#picture will be in test-suites/pictures
```


# Tests Evaluation

In our evaluation, we tested five widely used smart contracts—ETH TokenTransfer, Voting, Airdrop, CryptoKitties, and MillionPixel—along with MyToken (ERC20). These were executed on various blockchain systems including Sei, Aptos, Sui, Crystality, and PREDA. Detailed experiments were conducted to compare the performance of different parallel execution systems, focusing on both Transactions Per Second (TPS) and speedup ratios, which measure the performance gain on multiple VMs compared to each system’s baseline on a single VM.

# Comprehensive Experimental Evaluation of Major Parallel Execution Approaches in Blockchain

The figure below demonstrates the absolute throughput numbers in Transactions Per Second (TPS) of equivalent ERC20 smart contracts executed on Sei, Aptos, Sui, Crystality, and PREDA on a 128-core machine. This comparison underscores the necessity of adopting the PREDA programming model to achieve significant improvements in throughput and scalability. 

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfsQzxxVGUW8eHyJYY4zwp-pjPV1Y-DEctvmKT8lJvc0E39W524g2l_mO8TshKP-9C_rQWhwEZ8TAGg34YgqvTfChay1Jg9eQK2nWNSw73IzW67b0VwhYL0rTLPAv5SmnIMgqHMFXgXaWsqeBRW8tVda-OI?key=ZZA5bkPENOIsWAjdzWTInA)

Here, we will explain the methodology we used to create the chart above. Specifically, we will detail the data sources, the implementation processes, and the evaluation methods.

| Test Setup             |                                                              |
| :--------------------- | :----------------------------------------------------------- |
| **Hardware Setup**     | The performance comparisons are conducted on a high-performance multi-core machine equipped with two AMD EPYC 7742 CPUs (64-core, 2.25GHz - 3.4GHz max boost) and 2TB of memory, running Linux Ubuntu 20.04. |
| **Software Setup**     | The evaluation above focuses on experiments involving ERC token transfers on Ethereum. Subsequent evaluations in this piece cover a variety of smart contracts, including ETH Transfer, Voting, AirDrop, CryptoKitties, and MillionPixel, all of which were originally deployed and executed on Ethereum.<br/><br/>For Sei, the standard Solidity contracts are used. For Sui and Aptos, equivalent contracts are implemented in Sui Move and Aptos Move languages, respectively. <br/><br/>For the evaluation of PREDA and Crystality, the equivalent contracts are implemented in the PREDA language and the extended Solidity, respectively, with Crystality contracts being transformed into standard Solidity contracts using its source-to-source code transpiler. |
| **Experimental Setup** | The latest open-source code for these five systems is adopted from their  GitHub repositories. Specifically:<br/><br/>Sei: main branch, commit ID 35a7…1972<br/>Aptos: main branch, commit ID a182...7b0b<br/>Sui: testnet branch, commit ID 4dbc...c9a0<br/>Crystality: testnet branch, commit ID a8de...d0e1<br/>PREDA: testnet branch, commit ID a8de...d0e1 |
| **Data Source**        | In Sei, each lightweight Goroutine is managed by its Go runtime. Randomly generated transactions are used for the evaluation of ERC20, Voting, AirDrop, CryptoKitties, and MillionPixel. Specifically, 10,000 addresses and 100,000 transactions are generated for each system. <br><br/>For TokenTransfer, historical ETH transactions are replayed. The historical dataset comprises ETH transfer transactions from January 2024, with batches of 100,000 successive transactions prepared.  <br/><br/>Results are shown for the first batch, including 100,000 transactions from block heights 18,908,895 to 18,910,315 (12:00 am - 04:48 am, UTC, January 01, 2024). After conversion to the proper formats, the dataset is replayed on all five systems, respectively. |
| **Notes**              | In the evaluation, similar system setups are employed for parallel execution, excluding consensus overhead but including other elements like transaction signature verification. All five systems are configured in their single-node benchmark crates, and performance is optimized to the best extent possible. |

### How experiments were conducted

For all experiments, transaction volumes remain constant, while the number of parallel VMs varies with the number of CPU cores. In Sui, Aptos, Crystality, and PREDA, each thread is set to a dedicated CPU core. 

The experiments compare the absolute TPS numbers of all five systems (as throughput). Considering different programming languages and lower-level virtual machines adopted in the systems, to provide a fair comparison, the experiments also include the relative speedup results (as scalability), calculating the speedup on multiple VMs over each system’s baseline on one VM.

## Let the Numbers Do the Talking: Experiment Results with Six Representative Contracts

### 1. ERC20 Token Transfer Contract

**Source Contract:** [**https://solidity-by-example.org/app/erc20/**](https://solidity-by-example.org/app/erc20/)

The ERC20 contract in Solidity is designed for token transfer. It features a contract state *“balanceOf”* representing address balances and a *“transfer”* function to transfer a specified *“amount”* of tokens from the transaction sender *“msg.sender”* to a *“recipient”*. 

The experimental results illustrate the following absolute TPS and relative speedup figures:

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXcG0MIOjCdSh787muPIRJqv8m9IXS0upzmDs3z_et30nuIdlpU5Dcqkykfy3DYTbW34gBhAkjHs-4H-j8Dnjgmiqts7-QU3oUcXE5dcQTXHp3Byp6u1mnIWfIL69eTsVL-BN0tv-PMWKbHjYDCo_SZE1As?key=ZZA5bkPENOIsWAjdzWTInA)

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over Single Core** | **TPS Maximum over Multiple Cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 486                      | 3,846                               | 7.91x             |
| **Aptos**      | 2,472                    | 46,232                              | 18.70x            |
| **Sui**        | 1,644                    | 22,584                              | 13.73x            |
| **Crystality** | 3,272                    | 304,084                             | 92.93x            |
| **PREDA**      | 8,100                    | 629,830                             | 77.64x            |

### 2. ETH TokenTransfer Contract

This experiment was conducted using real historical ETH transactions. The smart contracts used were identical to standard ERC20 smart contracts. The experimental results are demonstrated as follows:

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXe9ycLxZvc1EWhTDeEG1H1DUtk8lAcZZ8ehZ_cXCjbkx3NlT3RLThwjNU_TvfM7EPzyERohxLREwYyMNjQqY39n9AQ8GGdy0f2vSOirG6Pt264QH8MFZbqx_rqwq68U5ASD8ArRF_N9br-nwyDAB5vPDWo?key=ZZA5bkPENOIsWAjdzWTInA)

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXcvhL1rZUTcoqHYmJk8tpnkXgC_aN3xLkD-PiBn4eJW-yFDHGzPg4i9OJmfv8L463anh2OQbNVSl3efoaJYZPRdjdwt8PQg4eOvLkiuN-7r8aA-bJUuOZXRnSKQ2E7NeQNKTW45t3Pzmn8WyJeOFbO-bNs?key=ZZA5bkPENOIsWAjdzWTInA)

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 350                      | 653                                 | 1.86x             |
| **Aptos**      | 2,459                    | 18,719                              | 7.61x             |
| **Sui**        | 1,558                    | 20,429                              | 13.11x            |
| **Crystality** | 3,267                    | 177,812                             | 54.42x            |
| **PREDA**      | 8,114                    | 352,112                             | 43.39x            |

Both absolute throughput numbers and scalability ratios are decreased in all five systems when replaying ETH historical transactions, compared to the ERC20 experiment. This is because repeated addresses in the historical transactions result in contentions (read-write or write-write), hindering the concurrent execution of these transactions in Parallel EVMs.  

### 3. The Voting Contract

**Source Contract:** https://docs.soliditylang.org/en/latest/solidity-by-example.html

The voting contract serves to gather voting results for proposal candidates. Originally, the algorithm implemented in Solidity is sequential, with users sharing a single array for voting results. An efficient parallel algorithm involves preparing a temporary array on each execution unit (VM). Users can then vote concurrently at different VMs, with the final result being aggregated from these temporary arrays. 

The Sei contract follows sequential algorithm, resulting in no speedup when running multiple EVMs. If the algorithm is not transformed to the parallel one, similar results will occur in other systems. For Aptos and Sui, the parallel implementations must initialize multiple resources at different addresses for temporary results of the “*proposal”* variable. Additionally, the parallel implementations must provide manual scheduling, based on voters' addresses, to direct voters’ transactions to different virtual machines and access temporary results for parallel execution. 

For Crystality and PREDA, the parallel implementation is much simpler. It only needs to use the *scope* keywords of the PREDA model when declaring “*proposal”* and its temporary variables. The voter-initiated transactions are automatically directed to corresponding virtual machines and executed by those virtual machines concurrently. 

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfLKA21sDqMg7XlQFiipy-FwFSWO4AF7z3pq2XouHJ00myuEHsfbTrl8ywwi9kh6Wy4NqwXEjIisWJF5gViiuqzhbtOvABG62_KH_8vXB3oXCkLLNf1wmWTo519yYH8XqxZ3HUOCc1HjYgPcLyRobSnwKly?key=ZZA5bkPENOIsWAjdzWTInA)

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfRDGEUuKrjMza5ZbNGC9kZn5Ua_cG_atS9JMCmU9szvAMW2v7NAXcpL2Bk-3z7uXUZknLWCQKrpd7lEPGzo2Mbdbo4_okh3sv1CHkOD7x5SXRPngUePppLt6qdCXS4NmFK_Z4RvgLoxctExAUITSrneyKi?key=ZZA5bkPENOIsWAjdzWTInA)

The experimental results illustrate the following absolute TPS and relative speedup figures:

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 400                      | 399                                 | 1.0x              |
| **Aptos**      | 3,874                    | 50,000                              | 12.9x             |
| **Sui**        | 1,352                    | 17,319                              | 12.8x             |
| **Crystality** | 3,378                    | 235,035                             | 69.57x            |
| **PREDA**      | 8,385                    | 758,303                             | 90.43x            |

The Voting smart contract demonstrates how the PREDA model can simplify the expression of the parallel voting algorithm and how the data partitioning, relay, and execution mechanisms in Crystality and PREDA can avoid the overhead in the optimistic parallelization method (Aptos) and pessimistic parallelization method (Sui) in both absolute TPS numbers and relative speedups. 

### 4. AirDrop 

**Source Contract:** https://github.com/SpringRole/smart-contracts/blob/master/contracts/AirDrop.sol

AirDrop is a widely used smart contract where a user-initiated transaction will trigger multiple token or NFT transfers from one address to multiple addresses. Compared to the ERC20 and Voting smart contracts, involving one-to-one and multiple-to-one state changes respectively, the AirDrop smart contract has a one-to-multiple state change mode. 

If the sender address or one destination address is involved in two AirDrop transactions, these two transactions cannot be executed concurrently in Sei, Aptos, or Sui. For example, Txn A involves an AirDrop from address 0 to states 1 and 2, and Txn B involves an AirDrop from address 0 to states 3 and 4. Txns A and B must be executed sequentially. 

In contrast, in the PREDA model, since the parallel granularity is broken down into each state access, both Crystality and PREDA can parallelize these two transactions in a pipeline mode. Txn A is decomposed into three steps: accessing states 0, 1, and 2; and Txn B is decomposed into accessing states 0, 3, and 4. Once accessing state 0 in Txn A and Txn B are completed sequentially, accessing states 1, 2, 3, and 4 can be executed by different virtual machines concurrently.

The experimental results illustrate the following absolute TPS and relative speedup figures:

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXed-BctAPiAwbDW3cYxi7mgLs3Wv8WgaiEC-Q564Y7mJko5rZI3LdkoT3IfV_lKBO_CNz24sP2EnfxqsorMdX4eBE7ZTj9VuQ31SRl-d1OLGBRqVJZABQobANdCPIg3r7u0rxwiL-NrJ4rlb6rKXndZchdq?key=ZZA5bkPENOIsWAjdzWTInA)

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXcVcfX4T9xzHkQCJO0o7wp14Xxf27S10DcRtWGc4cxhABwzmb1YV5DA0xXm46MtXmN_Ezflc7mOGx2D4W1V1dFu39lSxCaEWKh204xHaiw16BqWRyQId6KIWC7qZwAuQTh2TibL3gloE3c9sAS4QGOPf-Bx?key=ZZA5bkPENOIsWAjdzWTInA)

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 362                      | 922                                 | 2.54x             |
| **Aptos**      | 2,840                    | 55,309                              | 19.47x            |
| **Sui**        | 1,007                    | 15,513                              | 15.40x            |
| **Crystality** | 2,635                    | 181,318                             | 68.81x            |
| **PREDA**      | 7,002                    | 322,580                             | 46.06x            |

### 5. CryptoKitties

**Source Contract:** https://gist.github.com/arpit/071e54b95a81d13cb29681407680794f

This contract, a popular game contract on Ethereum, involves breeding digital cats based on genes from parent cats. Different from the previous ones, this contract needs to access multiple address states when processing a user-initiated transaction, including a *“sire kitty”*, a *“matron kitty”,* and a *“newborn kitty”*. This contract also involves more complicated computations than the previous ones when calculating the newborn’s gene from the parents’ genes.

The experimental results illustrate the following absolute TPS and relative speedup figures: 

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXc6zowd0Zfqm1-KYn9FY4GyHW1WwOtpy0bv1hpeb27ThxWUQSrWQa8_JitbEJyMlQZxCvkk4X_N1U8cZ_y4qtyjUDbrZunHtIn4YDZTg9YEEef90Nv9TLeDi7K8RtI4SfBsaH5WffjGByiWWXHt_7cO9lyP?key=ZZA5bkPENOIsWAjdzWTInA)

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXdYz2c4bF8dADmMVuu-c8Rd4unBIkBpbdfjRX6kArMdeHsxVGcYTS3fpTSMqxSiM2kGDvMoz5W8lc3LpHeKD62hLcgc3JXHMbsCdtWofZ5etFQpgVm9_PIyNPUrmbG7P5j5FYWRHLSSTnnis5txqDB9M-tW?key=ZZA5bkPENOIsWAjdzWTInA)

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 238                      | 262                                 | 1.10x             |
| **Aptos**      | 766                      | 2,449                               | 3.23x             |
| **Sui**        | 451                      | 9,150                               | 20.28x            |
| **Crystality** | 1,696                    | 95,524                              | 56.32x            |
| **PREDA**      | 6,161                    | 285,714                             | 46.37x            |

### 6. MillionPixel Contract

**Source Contract:** https://millionpixeldfi.github.io/

In this game contract on Ethereum, users compete to mark coordinates on a map. This smart contract is used to illustrate the flexibility of the PREDA model. Other than partitioning contract states by address, programmers can customize the partitioning key, e.g., from address type to uint32 type in this case.  

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXecJPWXbUWtFxKxe1__H_yQYosTKWb_CT4-YsvZ-5p-WZZmSMfsH5AwYng87DnDVwbTu90UB0Ygi-dkSvNsxNwXo1swhzgBaCbWXdwMVdeQPTGzPjCP5oIacoPch55J3kN6zHN-AYUMetTlGL0u37_wpWGf?key=ZZA5bkPENOIsWAjdzWTInA)

![img](https://lh7-rt.googleusercontent.com/docsz/AD_4nXeYznlFiRpvIN451EkYCi00JI5gH5dbJm_CW0B6S78nKEYr4IjzafAZQD2lngajaqtV6UYzwdJdSUO31imzts5v_YEKoWWmwkUJpP6rSFTWAkM4JBkYEDiJfBaOj32xjbYVesCcJRPDF5ChpFld-uxhdKlE?key=ZZA5bkPENOIsWAjdzWTInA)



The experimental results illustrate the following absolute TPS and relative speedup figures:

*TPS and Scalability Breakdown and Comparison*

|                | **TPS over single core** | **TPS maximum over multiple cores** | **Speedup Ratio** |
| -------------- | ------------------------ | ----------------------------------- | ----------------- |
| **Sei**        | 496                      | 5,851                               | 11.79x            |
| **Aptos**      | 3,653                    | 54,347                              | 14.87x            |
| **Sui**        | 1,027                    | 15,335                              | 14.93x            |
| **Crystality** | 3,386                    | 221,321                             | 65.36x            |
| **PREDA**      | 8,133                    | 654,222                             | 80.44x            |
