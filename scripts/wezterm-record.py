#!/usr/bin/env python3
import psutil
import subprocess
import time
from pathlib import Path


if __name__ == "__main__":
    statefile = Path().home() / ".local/state/wezterm"
    statefile.parent.mkdir(parents=True, exist_ok=True)

    while True:
        ctp = psutil.cpu_percent(0.25)
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
