#!/bin/bash

# Define the threshold values for CPU, memory, and disk usage (in percentage)
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

# Define the log file path
LOG_FILE="/var/log/system_monitor.log"

# Function to send an alert
send_alert() {
    echo "$(tput setaf 1)ALERT: $1 usage exceeded threshold! Current value: $2%$(tput sgr0)"
}

# Function to log resource usage
log_resource_usage() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] CPU: $1%, Memory: $2%, Disk: $3%" >> "$LOG_FILE"
}

# Ensure the log file exists and is writable
touch "$LOG_FILE"
if [ ! -w "$LOG_FILE" ]; then
    echo "$(tput setaf 1)ERROR: Cannot write to log file $LOG_FILE. Check permissions.$(tput sgr0)"
    exit 1
fi

while true; do
    # Monitor CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    cpu_usage=${cpu_usage%.*}
    if ((cpu_usage >= CPU_THRESHOLD)); then
        send_alert "CPU" "$cpu_usage"
    fi

    # Monitor memory
    memory_usage=$(free | awk '/Mem/ {printf("%3.1f", ($3/$2) * 100)}')
    if (( $(echo "$memory_usage >= $MEMORY_THRESHOLD" | bc -l) )); then
        send_alert "Memory" "$memory_usage"
    fi

    # Monitor disk
    disk_usage=$(df / | awk '/\// {print $(NF-1)}' | sed 's/%//')
    if ((disk_usage >= DISK_THRESHOLD)); then
        send_alert "Disk" "$disk_usage"
    fi

    # Log resource usage
    log_resource_usage "$cpu_usage" "$memory_usage" "$disk_usage"

    # Display current stats
    clear
    echo "Resource Usage:"
    echo "CPU: $cpu_usage%"
    echo "Memory: $memory_usage%"
    echo "Disk: $disk_usage%"
    echo "Logging to $LOG_FILE..."

    # Sleep for 2 seconds
    sleep 2
done