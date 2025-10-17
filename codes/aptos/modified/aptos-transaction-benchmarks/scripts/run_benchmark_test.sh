#!/bin/bash
bin_file="../../../target/release/aptos-transaction-benchmarks"
function run_airdrop {
    default_filename="../result/airdrop.log"
    filename=${1:-$default_filename}
    count=$(./../scripts/cpu_info.sh | awk '{print NF}')
    echo "run airdrop tasks" > $filename
    for ((i=1; i<=$count; i++)); do
        cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
        echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
        taskset -c $cores $bin_file airdrop --num-accounts 10000 --num-transactions 100000  >> $filename
        echo "" >> $filename
        echo "" >> $filename
        sleep 5s
    done
    echo "============================== finalize ==============================" >> $filename
    parallel_tps_data=($(cat $filename | grep "Parallel execution finishes" | awk -F '=' '{print $2}'))
    parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

    speed_up_data=()
    for num in "${parallel_tps_data[@]}"; do
        result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
        formatted_result=$(printf "%.2f" $result)
        speed_up_data+=("$formatted_result")
    done
    speed_up=$(IFS=,; echo "${speed_up_data[*]}")

    sequential_tps_data=($(cat $filename | grep "Sequential execution finishes" | awk -F '=' '{print $2}'))
    sequential_tps=$(IFS=,; echo "${sequential_tps_data[*]}")

    echo "parallel execution tps: [$parallel_tps]" >> $filename
    echo "speed up: [$speed_up]" >> $filename
    echo "sequential execution tps: [$sequential_tps]" >> $filename
}

function run_ballot {
    default_filename="../result/ballot.log"
    filename=${1:-$default_filename}
    count=$(./../scripts/cpu_info.sh | awk '{print NF}')

    echo "run ballot tasks" > $filename

    for ((i=1; i<=$count; i++)); do
        cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
        echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
        taskset -c $cores $bin_file ballot-sharding --num-accounts 100000 --num-transactions 100000 --num-shardings $((2 ** ((i-1))))  >> $filename
        echo "" >> $filename
        echo "" >> $filename
        sleep 5s
    done

    echo "============================== finalize ==============================" >> $filename

    parallel_tps_data=($(cat $filename | grep "Parallel execution finishes" | awk -F '=' '{print $2}'))
    parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

    speed_up_data=()
    for num in "${parallel_tps_data[@]}"; do
        result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
        formatted_result=$(printf "%.2f" $result)
        speed_up_data+=("$formatted_result")
    done
    speed_up=$(IFS=,; echo "${speed_up_data[*]}")

    sequential_tps_data=($(cat $filename | grep "Sequential execution finishes" | awk -F '=' '{print $2}'))
    sequential_tps=$(IFS=,; echo "${sequential_tps_data[*]}")

    echo "parallel execution tps: [$parallel_tps]" >> $filename
    echo "speed up: [$speed_up]" >> $filename
    echo "sequential execution tps: [$sequential_tps]" >> $filename
}

function run_erc20 {
    default_filename="../result/erc20.log"
    filename=${1:-$default_filename}
    count=$(./../scripts/cpu_info.sh | awk '{print NF}')

    echo "run erc20 transfer tasks" > $filename

    for ((i=1; i<=$count; i++)); do
        cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
        echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
        taskset -c $cores$bin_file param-sweep --num-accounts 10000 --block-sizes 100000  >> $filename
        echo "" >> $filename
        echo "" >> $filename
        sleep 5s
    done

    echo "============================== finalize ==============================" >> $filename

    parallel_tps_data=($(cat $filename | grep "Parallel execution finishes" | awk -F '=' '{print $2}'))
    parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

    speed_up_data=()
    for num in "${parallel_tps_data[@]}"; do
        result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
        formatted_result=$(printf "%.2f" $result)
        speed_up_data+=("$formatted_result")
    done
    speed_up=$(IFS=,; echo "${speed_up_data[*]}")

    sequential_tps_data=($(cat $filename | grep "Sequential execution finishes" | awk -F '=' '{print $2}'))
    sequential_tps=$(IFS=,; echo "${sequential_tps_data[*]}")

    echo "parallel execution tps: [$parallel_tps]" >> $filename
    echo "speed up: [$speed_up]" >> $filename
    echo "sequential execution tps: [$sequential_tps]" >> $filename
}

function run_eth_historical {
    default_filename="../result/eth_historical.log"
    filename=${1:-$default_filename}
    count=$(./../scripts/cpu_info.sh | awk '{print NF}')

    echo "run eth historical transfer tasks" > $filename

    for ((i=1; i<=$count; i++)); do
        cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
        echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
        taskset -c $cores $bin_file replay-erc20 --data-path "../data/ETH_2404_100000.csv"  >> $filename
        echo "" >> $filename
        echo "" >> $filename
        sleep 5s
    done

    echo "============================== finalize ==============================" >> $filename

    parallel_tps_data=($(cat $filename | grep "Parallel execution finishes" | awk -F '=' '{print $2}'))
    parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

    speed_up_data=()
    for num in "${parallel_tps_data[@]}"; do
        result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
        formatted_result=$(printf "%.2f" $result)
        speed_up_data+=("$formatted_result")
    done
    speed_up=$(IFS=,; echo "${speed_up_data[*]}")

    sequential_tps_data=($(cat $filename | grep "Sequential execution finishes" | awk -F '=' '{print $2}'))
    sequential_tps=$(IFS=,; echo "${sequential_tps_data[*]}")

    echo "parallel execution tps: [$parallel_tps]" >> $filename
    echo "speed up: [$speed_up]" >> $filename
    echo "sequential execution tps: [$sequential_tps]" >> $filename
}

function run_kitty {
    default_filename="../result/kitty.log"
    filename=${1:-$default_filename}
    count=$(./../scripts/cpu_info.sh | awk '{print NF}')

    echo "run kitty tasks" > $filename

    for ((i=1; i<=$count; i++)); do
        cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
        echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
        taskset -c $cores $bin_file kitty --num-accounts 1001 --num-transactions 10000  >> $filename
        echo "" >> $filename
        echo "" >> $filename
        sleep 5s
    done

    echo "============================== finalize ==============================" >> $filename

    parallel_tps_data=($(cat $filename | grep "Parallel execution finishes" | awk -F '=' '{print $2}'))
    parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

    speed_up_data=()
    for num in "${parallel_tps_data[@]}"; do
        result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
        formatted_result=$(printf "%.2f" $result)
        speed_up_data+=("$formatted_result")
    done
    speed_up=$(IFS=,; echo "${speed_up_data[*]}")

    sequential_tps_data=($(cat $filename | grep "Sequential execution finishes" | awk -F '=' '{print $2}'))
    sequential_tps=$(IFS=,; echo "${sequential_tps_data[*]}")

    echo "parallel execution tps: [$parallel_tps]" >> $filename
    echo "speed up: [$speed_up]" >> $filename
    echo "sequential execution tps: [$sequential_tps]" >> $filename
}

function run_million_pixel {
    default_filename="../result/million_pixel.log"
    filename=${1:-$default_filename}
    count=$(./../scripts/cpu_info.sh | awk '{print NF}')

    echo "run million_pixel tasks" > $filename

    for ((i=1; i<=$count; i++)); do
        cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
        echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
        taskset -c $cores $bin_file million-pixel --num-accounts 1001 --num-transactions 10000  >> $filename
        echo "" >> $filename
        echo "" >> $filename
        sleep 5s
    done

    echo "============================== finalize ==============================" >> $filename

    parallel_tps_data=($(cat $filename | grep "Parallel execution finishes" | awk -F '=' '{print $2}'))
    parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

    speed_up_data=()
    for num in "${parallel_tps_data[@]}"; do
        result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
        formatted_result=$(printf "%.2f" $result)
        speed_up_data+=("$formatted_result")
    done
    speed_up=$(IFS=,; echo "${speed_up_data[*]}")

    sequential_tps_data=($(cat $filename | grep "Sequential execution finishes" | awk -F '=' '{print $2}'))
    sequential_tps=$(IFS=,; echo "${sequential_tps_data[*]}")

    echo "parallel execution tps: [$parallel_tps]" >> $filename
    echo "speed up: [$speed_up]" >> $filename
    echo "sequential execution tps: [$sequential_tps]" >> $filename
}

cd ../src
run_airdrop
run_ballot
run_erc20
run_eth_historical
run_kitty
run_million_pixel


