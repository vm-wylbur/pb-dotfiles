#!/usr/bin/env python3
import psutil
import subprocess
import time
from pathlib import Path

statefile = Path().home() / ".local/state/wezterm"

if __name__ == "__main__":
    while True:
        p = psutil.Process()
        with p.oneshot():
            ctp = p.cpu_percent()
        line = '{"cpuusage": "' + f"{ctp}%" + '", '

        gig = 1024*1024*1024
        vm = psutil.virtual_memory()
        memfree = (f"{int(round(vm.available/gig, 0))}/"
                   f"{int(round(vm.total/gig, 0))}G")
        line += '"memfree": "' + f"{memfree}" + '", '

        ran = subprocess.run('smctemp -c', shell=True, text=True, capture_output=True)
        line += '"cputemp": "' + f"{int(round(float(ran.stdout), 0))}°C" + '" }\n'

        with open(statefile, "wt") as f:
            f.write(line)

        time.sleep(1)

# done
