#!/bin/bash


TIMELIMIT=$1 # Set time limit(Sec.)
SECONDS=0
while (( SECONDS < TIMELIMIT )); do
	sleep 1 &
	num_of_gpu=$(nvidia-smi --list-gpus | wc -l)
	for ((gpu = 1; gpu <= $num_of_gpu; gpu++)); do
		nvidia-smi --query-gpu=timestamp,temperature.gpu,gpu_bus_id --format=csv,noheader | sed -n "$gpu"p >> "gpu_$gpu.log" &
	done
	all_temp=$(nvidia-smi --query-gpu=timestamp,temperature.gpu --format=csv,noheader | cut -d ',' -f2)
	gpu_1=$(echo $all_temp | cut -d ' ' -f1)
	gpu_temp_sum=0
	for each_gpu in $all_temp; do
		gpu_temp_sum=$(($gpu_temp_sum+$each_gpu))
	done
	timestamp=$(nvidia-smi --query-gpu=timestamp,temperature.gpu,gpu_bus_id --format=csv,noheader | sed -n 1p | cut -d ',' -f1)
	average_temp=$(($gpu_temp_sum / $num_of_gpu))
	echo $timestamp" "$average_temp >> gpu_avg.log

	#cpu_temp_raw=$(sensors | grep Package)
	cpu_temp_raw=$(sensors | grep -m1 Tctl)
	temp=$(echo $cpu_temp_raw | cut -d ' ' -f2)
	echo $timestamp" "$temp >> cpu_temp.log
	wait
done
