#/bin/bash
TIMELIMIT=$1 # Set time limit(Sec.)
SECONDS=0
cpuinfo=$(lscpu | grep "Model name")
whichcpu=${cpuinfo:20:24}

while (( SECONDS < TIMELIMIT )); do
        sleep 5 &
        num_of_gpu=$(nvidia-smi --list-gpus | wc -l)

        for ((gpu = 1; gpu <= $num_of_gpu; gpu++)); do
                timestamp=$(date +%F_%T)
                smi=$(nvidia-smi --query-gpu=timestamp,temperature.gpu,gpu_bus_id,gpu_name --format=csv,noheader | sed -n "$gpu"p)
                echo $timestamp,$smi >> gpu_$gpu.csv &

        done
        all_temp=$(nvidia-smi --query-gpu=timestamp,temperature.gpu --format=csv,noheader | cut -d ',' -f2)
        gpu_1=$(echo $all_temp | cut -d ' ' -f1)
        gpu_temp_sum=0
        for each_gpu in $all_temp; do
                gpu_temp_sum=$(($gpu_temp_sum+$each_gpu))
        done
        # timestamp=$(nvidia-smi --query-gpu=timestamp,temperature.gpu,gpu_bus_id --format=csv,noheader | sed -n 1p | cut -d ',' -f1)
        timestamp=$(date +%F_%T)
        average_temp=$(($gpu_temp_sum / $num_of_gpu))
        echo $timestamp" "$average_temp >> gpu_avg.csv

        #cpu_temp_raw=$(sensors | grep Package)
        if [ $whichcpu == "Intel(R)" ] ; then
                num_of_cpu=$(sensors | grep Package | wc -l)
                if [ $num_of_cpu -eq 2 ] ; then
                        cpu1_sensor=$(sensors | grep "Package id 0")
                        cpu2_sensor=$(sensors | grep "Package id 1")
                        cpu1=$(echo $cpu1_sensor | cut -d ' ' -f4)
                        cpu2=$(echo $cpu2_sensor | cut -d ' ' -f4)
                        cpu1_temp=${cpu1:1:4}
                        cpu2_temp=${cpu2:1:4}
                        echo $timestamp,$cpu1_temp,$cpu2_temp >> cpu_temp.csv
                else
                        cpu1_sensor=$(sensors | grep "Package id 0")
                        cpu1=$(echo $cpu1_sensor | cut -d ' ' -f4)
                        cpu1_temp=${cpu1:1:4}
                        echo $timestamp,$cpu1_temp >> cpu_temp.csv
                fi
        else
                num_of_cpu=$(sensors | grep Tctl | wc -l)
                if [ $num_of_cpu -eq 2 ] ; then
                        cpu1_sensor=$(sensors | grep "Tctl 0")
                        cpu2_sensor=$(sensors | grep "Tctl 1")
                        cpu1=$(echo $cpu1_sensor | cut -d ' ' -f4)
                        cpu2=$(echo $cpu2_sensor | cut -d ' ' -f4)
                        cpu1_temp=${cpu1:1:4}
                        cpu2_temp=${cpu2:1:4}
                        echo $timestamp,$cpu1_temp,$cpu2_temp >> cpu_temp.csv
                else
                        cpu1_sensor=$(sensors | grep "Tctl")
                        cpu1=$(echo $cpu1_sensor | cut -d ' ' -f4)
                        cpu1_temp=${cpu1:1:4}
                        echo $timestamp,$cpu1_temp >> cpu_temp.csv
                fi
        fi
        wait
done
