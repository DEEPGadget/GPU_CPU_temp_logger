#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 <interval_in_seconds> <total_duration_in_seconds> [--no-gpu] [--no-wormhole]"
    echo "  --no-gpu: Optional flag to disable GPU temperature measurement"
    echo "  --no-wormhole: Optional flag to disable Tenstorrent N300 temperature measurement"
    exit 1
}

# Check if the number of arguments is valid
if [ $# -lt 2 ] || [ $# -gt 4 ]; then
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

# Initialize flags for disabling GPU and Wormhole N300 temperature measurement
NO_GPU=false
NO_WORMHOLE=false

# Check for flags in the provided arguments
if [ $# -ge 3 ]; then
    for arg in "${@:3}"; do
        if [ "$arg" == "--no-gpu" ]; then
            NO_GPU=true  # Disable GPU temperature measurement
        elif [ "$arg" == "--no-wormhole" ]; then
            NO_WORMHOLE=true  # Disable Wormhole N300 temperature measurement
        fi
    done
fi

# Path to the log file
LOG_FILE="thermal_log.csv"

# Calculate the total number of repetitions
REPEAT_COUNT=$((DURATION / INTERVAL))

# Check if the required commands are available
for cmd in nvme sensors free; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd command not found. Please install it and try again."
        exit 1
    fi
done

# Check if nvidia-smi is available when GPU temperature measurement is not disabled
if [ "$NO_GPU" == "false" ]; then
    if ! command -v nvidia-smi &> /dev/null; then
        echo "Error: nvidia-smi command not found. Please install it or use the --no-gpu flag."
        exit 1
    fi
    NUM_GPUS=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | sort | uniq)
else
    NUM_GPUS=0
fi

# Get the number of CPUs from the sensors command output
NUM_CPUS=$(sensors | grep -i 'k10temp-pci' | wc -l)

# Construct the CSV header
HEADER="Timestamp,NVMe_Temperature,CPU_Temperature"
if [ "$NO_GPU" == "false" ]; then
    for ((j=0; j<NUM_GPUS; j++)); do
        HEADER="$HEADER,GPU${j}_Temperature"  # Add GPU temperature headers if enabled
    done
fi

# Add Wormhole N300 temperature headers if the feature is not disabled
if [ "$NO_WORMHOLE" == "false" ]; then
    HEADER="$HEADER,Wormhole_N300_Temperatures"
fi

# Add memory usage headers
HEADER="$HEADER,MEM_TOTAL_MB,MEM_USED_MB"
echo $HEADER > $LOG_FILE

# Start the logging loop
for ((i=0; i<REPEAT_COUNT; i++)); do
    # Get the current timestamp
    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # Collect NVMe temperature
    NVME_TEMP=$(nvme smart-log /dev/nvme0n1 | grep 'temperature' | awk '{gsub(/[+°C]/, "", $3); print $3}')

    # Collect CPU temperatures
    CPU_TEMPS=""
    for ((j=0; j<NUM_CPUS; j++)); do
        # Use awk to extract Tctl values for each CPU and round them
        CPU_TEMP=$(sensors | awk -v cpu=$((j+1)) '/Tctl/ {count++; if (count==cpu) {gsub(/[+°C]/, "", $2); printf("%d", $2 + 0.5); exit}}')
        CPU_TEMPS="$CPU_TEMPS,$CPU_TEMP"  # Append each CPU temperature
    done

    # Collect memory usage information
    MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')  # Total memory in MB
    MEM_USED=$(free -m | awk '/Mem:/ {print $3}')  # Used memory in MB

    # Collect GPU temperatures if the feature is not disabled
    GPU_TEMPS=""
    if [ "$NO_GPU" == "false" ]; then
        for ((j=0; j<NUM_GPUS; j++)); do
            # Use nvidia-smi to get the temperature of each GPU
            GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits -i $j)
            GPU_TEMPS="$GPU_TEMPS,$GPU_TEMP"  # Append each GPU temperature
        done
    fi

    # Collect Wormhole N300 temperatures using regex if the feature is not disabled
    WORMHOLE_TEMPS=""
    if [ "$NO_WORMHOLE" == "false" ]; then
        # Use grep and regex to find all Wormhole N300 temperature values
        WORMHOLE_TEMPS=$(sensors | grep -A 3 -E 'wormhole-pci-[0-9]+' | grep 'asic1_temp' | awk '{gsub(/[+°C]/, "", $2); printf "%s,", $2}' | sed 's/,$//')
    fi

    # Write the collected data to the log file
    echo "$CURRENT_TIME,$NVME_TEMP$CPU_TEMPS$GPU_TEMPS,$WORMHOLE_TEMPS,${MEM_TOTAL}MB,${MEM_USED}MB" >> $LOG_FILE

    # Sleep for the specified interval before the next iteration
    sleep $INTERVAL
done
