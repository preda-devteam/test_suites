#!/bin/bash

default_filename="../result/ballot.log"
cd ../main
filename=${1:-$default_filename}
count=$(./../scripts/cpu_info.sh | awk '{print NF}')

echo "run ballot tasks" > $filename

for ((i=1; i<=$count; i++)); do
    cores=$(./../scripts/cpu_info.sh|cut -d ' ' -f$i)
    echo "============================== taskset in cpu: (${cores}) ==============================" >> $filename
    taskset -c $cores go run main.go ballot  >> $filename
    echo "" >> $filename
    echo "" >> $filename
    sleep 3s
done
content=$(<"$filename")

IFS=$'*' read -d '' -r -a sections < <(echo "$content" | awk '
BEGIN { RS="==============================[^=]*=============================="; ORS="*" }
{ if (NR > 1) print "(" $0 ")," }
END { if (NR > 0) print "(" $0 ")," }
')

median() {
    arr=($(printf '%s\n' "$@" | sort -n))
    len=${#arr[@]}
    if (( len % 2 == 1 )); then
        echo "${arr[$((len / 2))]}"
    else
        echo "(${arr[(len / 2) - 1]} + ${arr[len / 2]}) / 2" | bc
    fi
}

parallel_tps_data=()
unset 'sections[${#sections[@]}-1]'


for section in "${sections[@]}"; do
    tps_values=($(echo "$section" | grep -oP 'parallel tps:\s*\K\d+'))
    if [ ${#tps_values[@]} -gt 0 ]; then
        median_value=$(median "${tps_values[@]}")
        parallel_tps_data+=("$median_value")
    fi
done

echo "============================== finalize ==============================" >> $filename

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
