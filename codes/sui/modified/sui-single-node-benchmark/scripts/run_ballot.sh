#!/bin/bash
default_filename="./result/ballot.log"
filename=${1:-$default_filename}
count=$(./cpu_info.sh | awk '{print NF}')

echo "run ballot tasks" > $filename

for ((i=1; i<=$count; i++)); do
    cores=$(./cpu_info.sh|cut -d ' ' -f$i)
    echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
    taskset -c $cores cargo run --release --bin sui-single-node-benchmark -- --tx-count 100000 --component with-tx-manager ptb --num-shared-objects 1  >> $filename
    echo "" >> $filename
    echo "" >> $filename
    sleep 3s
done


echo "============================== finalize ==============================" >> $filename

parallel_tps_data=($(cat $filename | grep "Execution finished" | awk -F '=' '{print $2}'))
parallel_tps=$(IFS=,; echo "${parallel_tps_data[*]}")

speed_up_data=()
for num in "${parallel_tps_data[@]}"; do
    result=$(bc <<< "scale=2; $num / ${parallel_tps_data[0]}")
    formatted_result=$(printf "%.2f" $result)
    speed_up_data+=("$formatted_result")
done
speed_up=$(IFS=,; echo "${speed_up_data[*]}")


echo "parallel execution tps: [$parallel_tps]" >> $filename
echo "speed up: [$speed_up]" >> $filename
