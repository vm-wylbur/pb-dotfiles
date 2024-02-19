#!/usr/bin/env python3
import psutil
import subprocess
import time
from pathlib import Path
import platform
import fcntl
import os
import sys
from lockfile import LockFile, AlreadyLocked, LockTimeout

# only one instance can be running at a time.
LOCKFILE = Path().home() / ".local/state/wezterm.lock"
STATEFILE = Path().home() / ".local/state/wezterm"


def main():
    while True:
        ctp = psutil.cpu_percent(0.25)
        line = '{"cpuusage": "' + f"{ctp}%" + '", '

        gig = 1024*1024*1024
        vm = psutil.virtual_memory()
        memfree = (f"{int(round(vm.available/gig, 0))}/"
                   f"{int(round(vm.total/gig, 0))}G")
        line += '"memfree": "' + f"{memfree}" + '", '

        match platform.system():
            case "Linux":
                try:
                    cputmp = max([float(m.current)
                                  for m in
                                  psutil.sensors_temperatures()['coretemp']])
                    cputmp = f"{int(round(cputmp), 0))}°C"
                except ValueError:
                    cputmp = "xx"
                line += '"cputemp": "' + f"{cputmp}°C" + '" }\n'

            case "Darwin":
                # bc MacOS doesn't let psutil see core temps
                # git@github.com:narugit/smctemp.git
                ran = subprocess.run('smctemp -c', shell=True, text=True, capture_output=True)
                line += '"cputemp": "' + f"{int(round(float(ran.stdout), 0))}°C" + '" }\n'

            case other:
                raise NotImplementedError(f"what os? {platform.system()}")

        with open(STATEFILE, "wt") as f:
            f.write(line)

        time.sleep(1)


if __name__ == "__main__":
    STATEFILE.parent.mkdir(parents=True, exist_ok=True)

    try:
        with LockFile(LOCKFILE):
            main()
    # TODO: kill the other, or die.
    except (AlreadyLocked, LockTimeout):
        print("wezterm-record already running.")
        sys.exit(1)

# done
