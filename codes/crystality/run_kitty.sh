bin_file="../target/release/crystality-revm"
default_filename="result/Kitty.log"
filename=${1:-$default_filename}
echo "run Kitty task" > $filename

cores_per_sockets=$(lscpu | grep "Core(s) per socket:" | awk -F ':' '{print int($2)}' )
sockets=$(lscpu | grep "Socket(s):" | awk -F ':' '{print int($2)}' )
cores=$((cores_per_sockets*sockets))
for ((i=0;((2**i))<=$cores;i++));do
	core_list=$(./cpu_info.sh|cut -d ' ' -f$((i+1)))
	./$bin_file ./test_cases/KittyBreeding.xtlts -order:$i -cores:$core_list -perf >> $filename
done

echo "" >> $filename
echo "" >> $filename
echo "============================== finalize ==============================" >> $filename
parallel_tps_data=($(cat $filename | grep "TPS" | awk -F ':' '{print $2}'))
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
