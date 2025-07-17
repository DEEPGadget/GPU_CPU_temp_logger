#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 <interval_in_seconds> <total_duration_in_seconds> [--no-gpu] [--no-wormhole] [--no-nvme]"
    echo "  --no-gpu: Optional flag to disable GPU temperature measurement"
    echo "  --no-wormhole: Optional flag to disable Tenstorrent N300 temperature measurement"
    echo "  --no-nvme: Optional flag to disable NVMe temperature measurement"
    exit 1
}

# Check if the number of arguments is valid
if [ $# -lt 2 ] || [ $# -gt 5 ]; then
    usage
fi

# Validate that the interval and duration are positive integers
if ! [[ $1 =~ ^[0-9]+$ ]] || ! [[ $2 =~ ^[0-9]+$ ]]; then
    echo "Interval and duration must be positive integers."
    exit 1
fi

# Set the interval and total duration
INTERVAL=$1
DURATION=$2

# Initialize flags for disabling measurements
NO_GPU=false
NO_WORMHOLE=false
NO_NVME=false

# Check for flags in the provided arguments
if [ $# -ge 3 ]; then
    for arg in "${@:3}"; do
        case "$arg" in
            --no-gpu)
                NO_GPU=true  # Disable GPU temperature measurement
                ;;
            --no-wormhole)
                NO_WORMHOLE=true  # Disable Wormhole N300 temperature measurement
                ;;
            --no-nvme)
                NO_NVME=true  # Disable NVMe temperature measurement
                ;;
        esac
    done
fi

# Path to the log file
LOG_FILE="thermal_log.csv"

# Calculate the total number of repetitions
REPEAT_COUNT=$((DURATION / INTERVAL))

# Check if the required commands are available
for cmd in sensors free; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd command not found. Please install it and try again."
        exit 1
    fi
done

# Check for nvidia-smi if GPU monitoring is enabled
if [ "$NO_GPU" == "false" ] && ! command -v nvidia-smi &> /dev/null; then
    echo "Warning: nvidia-smi command not found. GPU temperatures will not be recorded."
    NO_GPU=true
fi

# Check if nvme command is available when NVMe monitoring is enabled
if [ "$NO_NVME" == "false" ] && ! command -v nvme &> /dev/null; then
    echo "Warning: nvme command not found. NVMe temperatures will not be recorded."
    NO_NVME=true
fi

# Get GPU count if monitoring is enabled
if [ "$NO_GPU" == "false" ]; then
    NUM_GPUS=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | sort | uniq)
else
    NUM_GPUS=0
fi

# Get the number of CPUs from the sensors command output
NUM_CPUS=$(sensors | grep -i 'k10temp-pci' | wc -l)

# Construct the CSV header
HEADER="Timestamp"
if [ "$NO_NVME" == "false" ]; then
    HEADER="$HEADER,NVMe_Temperature"
fi
HEADER="$HEADER,CPU_Temperature"
if [ "$NO_GPU" == "false" ]; then
    for ((j=0; j<NUM_GPUS; j++)); do
        HEADER="$HEADER,GPU${j}_Temperature"
    done
fi
if [ "$NO_WORMHOLE" == "false" ]; then
    HEADER="$HEADER,Wormhole_N300_Temperatures"
fi
HEADER="$HEADER,MEM_TOTAL_MB,MEM_USED_MB"
echo $HEADER > $LOG_FILE

# Start the logging loop
for ((i=0; i<REPEAT_COUNT; i++)); do
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # Collect NVMe temperature if enabled
    if [ "$NO_NVME" == "false" ]; then
        NVME_TEMP=$(nvme smart-log /dev/nvme0n1 2>/dev/null | grep 'temperature' | awk '{gsub(/[+°C]/, "", $3); print $3}')
        NVME_TEMP=${NVME_TEMP:-"N/A"}  # Default to N/A if command fails
    fi

    # Collect CPU temperatures
    CPU_TEMPS=""
    for ((j=0; j<NUM_CPUS; j++)); do
        CPU_TEMP=$(sensors | awk -v cpu=$((j+1)) '/Tctl/ {count++; if (count==cpu) {gsub(/[+°C]/, "", $2); printf("%d", $2 + 0.5); exit}}')
        CPU_TEMPS="$CPU_TEMPS,$CPU_TEMP"
    done

    # Collect memory usage information
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')

    # Collect GPU temperatures if enabled
    GPU_TEMPS=""
    if [ "$NO_GPU" == "false" ]; then
        for ((j=0; j<NUM_GPUS; j++)); do
            GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits -i $j)
            GPU_TEMPS="$GPU_TEMPS,$GPU_TEMP"
        done
    fi

    # Collect Wormhole N300 temperatures if enabled
    WORMHOLE_TEMPS=""
    if [ "$NO_WORMHOLE" == "false" ]; then
        WORMHOLE_TEMPS=$(sensors | grep -A 3 -E 'wormhole-pci-[0-f]+' | grep 'asic1_temp' | awk '{gsub(/[+°C]/, "", $2); printf "%s,", $2}' | sed 's/,$//')
    fi

    # Assemble the log entry
    LOG_ENTRY="$CURRENT_TIME"
    if [ "$NO_NVME" == "false" ]; then
        LOG_ENTRY="$LOG_ENTRY,$NVME_TEMP"
    fi
    LOG_ENTRY="$LOG_ENTRY$CPU_TEMPS$GPU_TEMPS,$WORMHOLE_TEMPS,${MEM_TOTAL}MB,${MEM_USED}MB"

    # Write the collected data to the log file
    echo "$LOG_ENTRY" >> $LOG_FILE

    # Sleep for the specified interval
    sleep $INTERVAL
done
