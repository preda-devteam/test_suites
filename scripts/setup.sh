#! /bin/bash

workspace=$(pwd)

aptos_modified_codes=${workspace}/../codes/aptos/modified
aptos_original_codes=${workspace}/../codes/aptos/original

sui_modified_codes=${workspace}/../codes/sui/modified
sui_original_codes=${workspace}/../codes/sui/original

sei_modified_codes=${workspace}/../codes/sei/modified
sei_original_codes=${workspace}/../codes/sei/original

aptos_proj=${workspace}/../repos/aptos-core
sui_proj=${workspace}/../repos/sui
preda_proj=${workspace}/../repos/preda
sei_proj=${workspace}/../repos/sei-chain
crystality_proj=${workspace}/../repos/crystality-revm

aptos_move=${aptos_proj}/aptos-move
sui_crates=${sui_proj}/crates

if [ ! -d "${workspace}/../repos" ];then
    mkdir ${workspace}/../repos
fi

function aptos_env {
    if [ -d "${aptos_proj}" ]; then
        echo "aptos repo has been cloned."
    else
        cd ${workspace}/../repos
        if git clone --branch main https://github.com/aptos-labs/aptos-core.git; then
            cd aptos-core && git checkout a1822a4fa0912166069822fb1080a006f32d7b0b   
            echo "save source files..."
            mkdir -p $(dirname ${aptos_original_codes}/aptos-transaction-benchmarks/Cargo.toml) && cp ${aptos_move}/aptos-transaction-benchmarks/Cargo.toml ${aptos_original_codes}/aptos-transaction-benchmarks/Cargo.toml
            mkdir -p $(dirname ${aptos_original_codes}/aptos-transaction-benchmarks/src/lib.rs) && cp ${aptos_move}/aptos-transaction-benchmarks/src/lib.rs ${aptos_original_codes}/aptos-transaction-benchmarks/src/lib.rs
            mkdir -p $(dirname ${aptos_original_codes}/aptos-transaction-benchmarks/src/main.rs) && cp ${aptos_move}/aptos-transaction-benchmarks/src/main.rs ${aptos_original_codes}/aptos-transaction-benchmarks/src/main.rs
            
            mkdir -p $(dirname ${aptos_original_codes}/e2e-tests/src/account_universe/universe.rs) && cp ${aptos_move}/e2e-tests/src/account_universe/universe.rs ${aptos_original_codes}/e2e-tests/src/account_universe/universe.rs
            mkdir -p $(dirname ${aptos_original_codes}/e2e-tests/src/account_universe/peer_to_peer.rs) && cp ${aptos_move}/e2e-tests/src/account_universe/peer_to_peer.rs ${aptos_original_codes}/e2e-tests/src/account_universe/peer_to_peer.rs
            mkdir -p $(dirname ${aptos_original_codes}/e2e-tests/src/account_universe.rs) && cp ${aptos_move}/e2e-tests/src/account_universe.rs ${aptos_original_codes}/e2e-tests/src/account_universe.rs
            mkdir -p $(dirname ${aptos_original_codes}/e2e-tests/src/common_transactions.rs) && cp ${aptos_move}/e2e-tests/src/common_transactions.rs ${aptos_original_codes}/e2e-tests/src/common_transactions.rs
            mkdir -p $(dirname ${aptos_original_codes}/e2e-tests/src/executor.rs) && cp ${aptos_move}/e2e-tests/src/executor.rs ${aptos_original_codes}/e2e-tests/src/executor.rs

            mkdir -p $(dirname ${aptos_original_codes}/block-executor/src/executor.rs) && cp ${aptos_move}/block-executor/src/executor.rs ${aptos_original_codes}/block-executor/src/executor.rs
        else
            echo "clone aptos repo failed."
            return -1 
        fi
    fi

    #overwrite files
    echo "overwrite some files..."
    cp ${aptos_modified_codes}/aptos-transaction-benchmarks/Cargo.toml ${aptos_move}/aptos-transaction-benchmarks/Cargo.toml
    cp ${aptos_modified_codes}/aptos-transaction-benchmarks/src/lib.rs ${aptos_move}/aptos-transaction-benchmarks/src/lib.rs
    cp ${aptos_modified_codes}/aptos-transaction-benchmarks/src/main.rs ${aptos_move}/aptos-transaction-benchmarks/src/main.rs
    cp ${aptos_modified_codes}/aptos-transaction-benchmarks/src/simulator.rs ${aptos_move}/aptos-transaction-benchmarks/src/simulator.rs
    cp -r ${aptos_modified_codes}/aptos-transaction-benchmarks/data ${aptos_move}/aptos-transaction-benchmarks
    cp -r ${aptos_modified_codes}/aptos-transaction-benchmarks/scripts ${aptos_move}/aptos-transaction-benchmarks
    
    cp ${aptos_modified_codes}/e2e-tests/src/account_universe/universe.rs ${aptos_move}/e2e-tests/src/account_universe/universe.rs
    cp ${aptos_modified_codes}/e2e-tests/src/account_universe/peer_to_peer.rs ${aptos_move}/e2e-tests/src/account_universe/peer_to_peer.rs
    cp ${aptos_modified_codes}/e2e-tests/src/account_universe.rs ${aptos_move}/e2e-tests/src/account_universe.rs 
    cp ${aptos_modified_codes}/e2e-tests/src/common_transactions.rs ${aptos_move}/e2e-tests/src/common_transactions.rs 
    cp ${aptos_modified_codes}/e2e-tests/src/executor.rs ${aptos_move}/e2e-tests/src/executor.rs 
    
    cp ${aptos_modified_codes}/block-executor/src/executor.rs ${aptos_move}/block-executor/src/executor.rs

    cp ${aptos_modified_codes}/move-contracts/xtl_airdrop.move ${aptos_move}/framework/aptos-framework/sources/xtl_airdrop.move
    cp ${aptos_modified_codes}/move-contracts/xtl_ballot.move ${aptos_move}/framework/aptos-framework/sources/xtl_ballot.move
    cp ${aptos_modified_codes}/move-contracts/xtl_kitty.move ${aptos_move}/framework/aptos-framework/sources/xtl_kitty.move
    cp ${aptos_modified_codes}/move-contracts/xtl_million_pixel.move ${aptos_move}/framework/aptos-framework/sources/xtl_million_pixel.move
    cp ${aptos_modified_codes}/move-contracts/xtl_empty.move ${aptos_move}/framework/aptos-framework/sources/xtl_empty.move

    sleep 3s
    echo "finish, let's go build!"
    cd ${aptos_move}/aptos-transaction-benchmarks
    cargo build --release
}

function sui_env {
    if [ -d "${sui_proj}" ]; then
        echo "sui repo has been cloned."
    else
        cd ${workspace}/../repos
        if git clone --branch testnet https://github.com/MystenLabs/sui; then
            cd sui && git checkout 4dbcf811abde03f8b1b2bf127a0215f2f966c9c0
            # save source files
            echo "save source files..."
            cp -r ${sui_crates}/sui-single-node-benchmark ${sui_original_codes}
        else
            echo "clone sui repo failed."
            return -1 
        fi
    fi
    
    # overwrite files
    echo "overwrite some files..."
    cp -r ${sui_modified_codes}/sui-single-node-benchmark ${sui_crates}

    sleep 3s
    echo "finish, let's go build!"
    cd ${sui_crates}/sui-single-node-benchmark
    cargo build --release --bin sui-single-node-benchmark
}

function sei_env {
    if [ -d "${sei_proj}" ]; then
        echo "sei repo has been cloned."
    else
        cd ${workspace}/../repos
        if git clone --branch main https://github.com/sei-protocol/sei-chain.git;then
            cd sei-chain && git checkout 867aaec65aef3d0e25e746198a6449ea494471a3
            cp -r ${sei_proj}/app/app.go ${sei_original_codes}/app/
            cp -r ${sei_proj}/occ_tests ${sei_original_codes}
        else
            echo "clone sei repo failed."
            return -1  
        fi
    fi
    cp ${sei_modified_codes}/app/app.go ${sei_proj}/app/
    cp -r ${sei_modified_codes}/occ_tests ${sei_proj}/
    cd ${sei_proj} && go mod tidy
}

function preda_env {
    if [ -d "${preda_proj}" ]; then
        echo "preda repo has been cloned."
    else
        cd ${workspace}/../repos
        if git clone --branch main https://github.com/preda-devteam/preda.git;then
            cd preda
            if git submodule update --init;then
                cmake -S ./ -B ./build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DDOWNLOAD_IPP=ON -DDOWNLOAD_3RDPARTY=ON -DBUNDLE_OPS=ON
                cmake --build ./build --target bundle_package
            else
                echo "clone preda submodule repo failed. please redo: git submodule update --init &&  cmake -S ./ -B ./build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DDOWNLOAD_IPP=ON -DDOWNLOAD_3RDPARTY=ON -DBUNDLE_OPS=ON && cmake --build ./build"
                return -1  
            fi
        else
            echo "clone preda repo failed."
            return -1  
        fi
    fi
    if [ -d "${workspace}/../repos/preda/bundle/preda-toolchain/opt/PREDA/bin" ]; then
        cd ${workspace}/../repos/preda/bundle/preda-toolchain/opt/PREDA/bin
        cp ${workspace}/../codes/preda/*.sh .
        cd ${workspace}/../repos/preda/bundle/preda-toolchain/opt/PREDA
        cp -r ${workspace}/../codes/preda/test_cases .
    fi

}

function crystality_revm_env {
    if [ -d "${crystality_proj}" ]; then
        echo "crystality_revm repo has been cloned."
        cd ${workspace}/../repos
        cd crystality-revm
    else
        cd ${workspace}/../repos
        if git clone --branch main https://github.com/preda-devteam/crystality-revm.git;then
            cd crystality-revm
        else
            echo "clone crystality-revm repo failed."
            return -1  
        fi
    fi
    echo "finish, let's go build!"
    cargo build --release
    mkdir -p tests
    cp -r ${workspace}/../codes/crystality/* tests/
}

case $1 in
    aptos)
        echo "setup aptos repo..."
        aptos_env
        ;;
    sui)
        echo "setup sui repo..."
        sui_env
        ;;
    preda)
        echo "setup preda repo..."
        preda_env
        ;;
    sei)
        echo "setup sei repo..."
        sei_env
        ;;
    crystality)
        echo "setup crystality-revm repo..."
        crystality_revm_env
        ;;
    *)
        echo "setup aptos/sui/sei/preda/crystality repo..."
        aptos_env
        sui_env
        preda_env
        sei_env
        crystality_revm_env
        ;;
esac

cd ${workspace}
pip install -r requirements.txt 
