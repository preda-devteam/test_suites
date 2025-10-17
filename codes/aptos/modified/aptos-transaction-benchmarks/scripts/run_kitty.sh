#!/bin/bash
bin_file="../../../target/release/aptos-transaction-benchmarks"
default_filename="../result/kitty.log"
filename=${1:-$default_filename}
cd ../src
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
