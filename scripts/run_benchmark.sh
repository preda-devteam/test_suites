#!/bin/bash

param=$1
workspace=$(pwd)
result_dir=${workspace}/../results
aptos="../repos/aptos-core/aptos-move/aptos-transaction-benchmarks/scripts"
sui="../repos/sui/crates/sui-single-node-benchmark/scripts"
preda="../repos/preda/bundle/preda-toolchain/opt/PREDA/bin"
sei="../repos/sei-chain/occ_tests/scripts"

if [ ! -d "${result_dir}" ];then
    mkdir ${result_dir}
fi

function run_airdrop {
    if [ ! -d "${result_dir}/airdrop" ];then
        mkdir ${result_dir}/airdrop
    fi
    cd ${aptos}
    ./run_airdrop.sh ${result_dir}/airdrop/airdrop_Aptos.log
    cd ${workspace} && cd ${sui}
    ./run_airdrop.sh ${result_dir}/airdrop/airdrop_Sui.log
    cd ${workspace} && cd ${preda}
    ./run_airdrop.sh ${result_dir}/airdrop/airdrop_Preda.log
    cd ${workspace} && cd ${sei}
    ./run_airdrop.sh ${result_dir}/airdrop/airdrop_Sei.log
}

function run_ballot {
    if [ ! -d "${result_dir}/ballot" ];then
        mkdir ${result_dir}/ballot
    fi
    cd ${aptos}
    ./run_ballot.sh ${result_dir}/ballot/ballot_Aptos.log
    cd ${workspace} && cd ${sui}
    ./run_ballot_sharding.sh ${result_dir}/ballot/ballot_Sui.log
    cd ${workspace} && cd ${preda}
    ./run_ballot.sh ${result_dir}/ballot/ballot_Preda.log
    cd ${workspace} && cd ${sei}
    ./run_ballot.sh ${result_dir}/ballot/ballot_Sei.log
}

function run_erc20 {
    if [ ! -d "${result_dir}/erc20" ];then
        mkdir ${result_dir}/erc20
    fi
    cd ${aptos}
    ./run_erc20_transfer.sh ${result_dir}/erc20/erc20_Aptos.log
    cd ${workspace} && cd ${sui}
    ./run_erc20_transfer.sh ${result_dir}/erc20/erc20_Sui.log
    cd ${workspace} && cd ${preda}
    ./run_erc20_transfer.sh ${result_dir}/erc20/erc20_Preda.log
    cd ${workspace} && cd ${sei}
    ./run_erc20_transfer.sh ${result_dir}/erc20/erc20_Sei.log
}


function run_eth_historical {
    if [ ! -d "${result_dir}/eth_historical" ];then
        mkdir ${result_dir}/eth_historical
    fi
    cd ${aptos}
    ./run_eth_historical.sh ${result_dir}/eth_historical/eth_historical_Aptos.log
    cd ${workspace} && cd ${sui}
    ./run_erc20_replay.sh ${result_dir}/eth_historical/eth_historical_Sui.log
    cd ${workspace} && cd ${preda}
    ./run_eth_historical.sh ${result_dir}/eth_historical/eth_historical_Preda.log
    cd ${workspace} && cd ${sei}
    ./run_eth_historical.sh ${result_dir}/eth_historical/eth_historical_Sei.log
}

function run_kitty {
    if [ ! -d "${result_dir}/kitty" ];then
        mkdir ${result_dir}/kitty
    fi
    cd ${aptos}
    ./run_kitty.sh ${result_dir}/kitty/kitty_Aptos.log
    cd ${workspace} && cd ${sui}
    ./run_kitty.sh ${result_dir}/kitty/kitty_Sui.log
    cd ${workspace} && cd ${preda}
    ./run_kitty.sh ${result_dir}/kitty/kitty_Preda.log
    cd ${workspace} && cd ${sei}
    ./run_kitty.sh ${result_dir}/kitty/kitty_Sei.log
}

function run_million_pixel {
    if [ ! -d "${result_dir}/million_pixel" ];then
        mkdir ${result_dir}/million_pixel
    fi
    cd ${aptos}
    ./run_million_pixel.sh ${result_dir}/million_pixel/million_pixel_Aptos.log
    cd ${workspace} && cd ${sui}
    ./run_million_pixel_sharding.sh ${result_dir}/million_pixel/million_pixel_Sui.log
    cd ${workspace} && cd ${preda}
    ./run_million_pixel.sh ${result_dir}/million_pixel/million_pixel_Preda.log
    cd ${workspace} && cd ${sei}
    ./run_million_pixel.sh ${result_dir}/million_pixel/million_pixel_Sei.log
}

case $param in
    airdrop)
        run_airdrop
        cd ${workspace}
        python3 draw.py airdrop
        ;;
    ballot)
        run_ballot
        cd ${workspace}
        python3 draw.py ballot
        ;;
    erc20)
        run_erc20
        cd ${workspace}
        python3 draw.py erc20
        ;;
    replay)
        run_eth_historical
        cd ${workspace}
        python3 draw.py eth_historical
        ;;
    kitty)
        run_kitty
        cd ${workspace}
        python3 draw.py kitty
        ;;
    million_pixel)
        run_million_pixel
        cd ${workspace}
        python3 draw.py million_pixel
        ;;
    all)
        run_airdrop
        cd ${workspace}
        run_ballot
        cd ${workspace}
        run_erc20
        cd ${workspace}
        run_eth_historical
        cd ${workspace}
        run_kitty
        cd ${workspace}
        run_million_pixel
        cd ${workspace}
        python3 draw.py airdrop
        python3 draw.py ballot
        python3 draw.py erc20
        python3 draw.py eth_historical
        python3 draw.py kitty
        python3 draw.py million_pixel
        ;;
    *)
        echo "Usage: $0 {airdrop|ballot|erc20|replay|kitty|million_pixel|all}"
        exit 1
        ;;
esac
