#!/bin/bash
# from `top -l 1`
# Load Avg: 2.95, 2.75, 2.59
# CPU usage: 6.90% user, 13.50% sys, 79.58% idle
# SharedLibs: 1036M resident, 172M data, 131M linkedit.
# MemRegions: 1174994 total, 22G resident, 1259M private, 7649M shared.
# PhysMem: 57G used (3268M wired, 1552M compressor), 6795M unused.


while true; do
    TOP=$(top -l 1)
    # echo $TOP

    # cpuu=$(echo "${TOP}" | grep "CPU usage" | awk '{print $7}')
    # cpuusage=$(printf %.2f $(echo "100 - ${cpuu%?}" | bc))
    cpuusage=$(python -c 'import psutil; psutil.cpu_times_percent(0.2); print(f"{100 - psutil.cpu_times_percent(0.1).idle:3.1f}")')
    cpuusage=$(echo "${cpuusage}%" | base64)
    printf "\033]1337;SetUserVar=%s=%s\007" "cpuusage" $cpuusage

    cputemp=$(printf '%.0f' $(smctemp -c))
    cputemp=$(echo "${cputemp}°C" | base64 )
    printf "\033]1337;SetUserVar=%s=%s\007" "cputemp" $cputemp

    memfree=$(python -c 'import psutil; gig = 1024*1024*1024; vm = psutil.virtual_memory(); print(f"{int(round(vm.available/gig, 0))}/{int(round(vm.total/gig,0))}G")')
    export WEZTERM_MEMFREE="${memfree}"

    memfree=$(echo "${memfree}" | base64)
    printf "\033]1337;SetUserVar=%s=%s\007" "memfree" $memfree

    sleep 1
done
# done
