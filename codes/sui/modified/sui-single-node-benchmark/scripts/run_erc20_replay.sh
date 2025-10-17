#!/bin/bash
bin_file="../../../target/release/sui-single-node-benchmark"
default_filename="./result/erc20_replay.log"
filename=${1:-$default_filename}
count=$(./cpu_info.sh | awk '{print NF}')

echo "run erc20 replay tasks" > $filename

for ((i=1; i<=$count; i++)); do
    cores=$(./cpu_info.sh|cut -d ' ' -f$i)
    echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
    taskset -c $cores $bin_file --account-path "./../data/USDT_100k_addr_count.csv" --erc20-tx-path "./../data/USDT_240101_240331_data_100000.csv" --component with-tx-manager ptb --erc20-transfer >> $filename
    echo "" >> $filename
    echo "" >> $filename
    sleep 3s
done


echo "============================== finalize ==============================" >> $filename

prepare_time=($(cat $filename | grep "batch_create_account_and_gas_by_index finished" |tr -d '\r'| awk '{print $NF}'|sed 's/s//'))
execution_time=($(cat $filename | grep "Execution finished in" | cut -d ' ' -f4|sed 's/s,//'))

time=()
for ((i=0;i<${#prepare_time[@]};i++));do
    sum=$(echo "${prepare_time[i]} + ${execution_time[i]}" | bc)
    time+=("$sum")
done

txns=($(cat $filename | grep "Generate tx from csv," | cut -d ' ' -f6))
parallel_tps_data=()
speed_up_data=()
for ((i=0;i<${#time[@]};i++));do
    tps_result=$(bc <<< "scale=0; $txns / ${time[i]}")
    parallel_tps_data+=("${tps_result}")
done

for num in "${parallel_tps_data[@]}"; do
    result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
    formatted_result=$(printf "%.2f" $result)
    speed_up_data+=("$formatted_result")
done

parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")


speed_up=$(IFS=,; echo "${speed_up_data[*]}")



echo "parallel execution tps: [$parallel_tps]" >> $filename
echo "speed up: [$speed_up]" >> $filename

