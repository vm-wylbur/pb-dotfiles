#!/usr/bin/env python3
import psutil
import subprocess
import time
from datetime import datetime
from pathlib import Path
import platform
import signal
import os
import re

STATEFILE = Path().home() / ".local/state/wezterm"
S2 = Path().home() / ".local/state/wezterm.json"


def main():
    while True:
        ctp = psutil.cpu_percent(0.25)
        line = '{ "cpuusage": "' + f"{ctp}%" + '", '

        dtime = int(datetime.now().strftime("%s"))
        line += '"timestamp": "' + f"{dtime}" + '", '

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
                    cputmp = f"{int(round(cputmp), 0)}°C"
                except ValueError:
                    cputmp = "xx"
                line += '"cputemp": "' + f"{cputmp}°C" + '" }\n'

        gig = 1024.0*1024*1024
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
                    cputmp = f"{int(round(cputmp), 0)}°C"
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


def only_me():
    ws = re.compile(r'\s+')
    ran = subprocess.run("ps ax".split(' '), capture_output=True, text=True)

    ps_ax = {line for line in ran.stdout.split('\n')
             if 'python' in line and 'wezterm-record.py' in line}

    pids = {int(ws.split(row)[0]) for row in ps_ax} - {os.getpid()}

    for pid in pids:
        os.kill(pid, signal.SIGHUP)


if __name__ == "__main__":
    STATEFILE.parent.mkdir(parents=True, exist_ok=True)
    only_me()
    main()

# done
