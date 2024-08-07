#!/bin/bash

usage() {
	    echo "Usage: $0 <interval_in_seconds> <total_duration_in_seconds>"
	        exit 1
	}
	
	# 인자 확인
if [ $# -ne 2 ]; then
    usage
fi
	    
# 측정 간격 및 총 측정 시간 설정
INTERVAL=$1
DURATION=$2
		    
# 로그 파일 경로 설정
LOG_FILE="thermal_log.csv"
		    
# 총 반복 횟수 계산
REPEAT_COUNT=$((DURATION / INTERVAL))

NUM_GPUS=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | sort | uniq)
NUM_CPUS=$(sensors | grep -i 'k10temp-pci' | wc -l)

HEADER="Timestamp, NVMe_Temperature"
for ((j=0; j<NUM_GPUS; j++))
do
	HEADER="$HEADER, GPU${j}_Temperature"
done

HEADER="$HEADER, MEM_TOTAL_MB, MEM_USED_MB"
echo $HEADER > $LOG_FILE




# 루프 시작
for ((i=0; i<REPEAT_COUNT; i++))
do
	# 현재 시간 가져오기
	CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
				        
	# NVMe 온도 정보 가져오기
	#NVME_TEMP=$(nvme smart-log /dev/nvme0n1 | grep 'temperature' | awk '{print $3"°C"}')
	NVME_TEMP=$(nvme smart-log /dev/nvme0n1 | grep 'temperature' | awk '{gsub(/[+°C]/, "", $3); print $3}') 
				        
	# CPU 온도 정보 가져오기
	CPU_TEMPS=""
	for ((j=0; j<NUM_CPUS; j++))
	do
		CPU_TEMP=$(sensors | awk -v cpu=$((j+1)) '/Tctl/ {count++; if (count==cpu) {gsub(/[+°C]/, "", $2); printf("%d", $2 + 0.5); exit}}')
		# append current CPU_TEMP to previous CPU_TEMPS
		CPU_TEMPS="$CPU_TEMPS, $CPU_TEMP"
	done					        
	# 메모리 온도 정보 가져오기 (예: DDR 메모리 온도)
	MEM_TEMP=$(sensors | grep 'temp1' | awk '{print $2}')
							        
	# 메모리 사용량 정보 가져오기
	MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
	MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
				
	# GPU info
	GPU_TEMPS=""
	for ((j=0; j<NUM_GPUS; j++))
	do
		GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits -i $j | awk '{print $1""}')
		GPU_TEMPS="$GPU_TEMPS, $GPU_TEMP"
	done	
	# 로그 파일에 시간과 온도 정보 저장
	echo "$CURRENT_TIME, $NVME_TEMP$CPU_TEMPS$GPU_TEMPS, ${MEM_TOTAL}MB, ${MEM_USED}MB" >> $LOG_FILE
										    
	# 설정된 간격만큼 대기
	sleep $INTERVAL
done
