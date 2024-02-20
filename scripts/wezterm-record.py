#!/usr/bin/env python3
import psutil
import subprocess
import time
from datetime import datetime
from pathlib import Path
import json
import platform
import signal
import os
import re

STATEFILE = Path().home() / ".local/state/wezterm"
STATEJSON = Path().home() / ".local/state/wezterm.json"


def main():
    while True:
        ctp = psutil.cpu_percent(0.25)
        # line = '{"cpuusage": "' + f"{ctp:>4}%" + '", '
        outputs = {"cpuusage": f"{ctp:>4}%"}

        dtime = int(datetime.now().strftime("%s"))
        # line += '"timestamp": "' + f"{dtime}" + '", '
        outputs["timestamp"] = f"{dtime}"

        gig = 1024*1024*1024.0
        vm = psutil.virtual_memory()
        memfree = (f"{int(round(vm.available/gig, 0))}/"
                   f"{int(round(vm.total/gig, 0))}G")

        # line += '"memfree": "' + f"{memfree}" + '", '
        outputs["memfree"] = memfree

        cputmp = ""
        match platform.system():
            case "Linux":
                try:
                    cputmp = max([float(m.current)
                                  for m in
                                  psutil.sensors_temperatures()['coretemp']])
                    cputmp = f"{int(round(cputmp, 0))}°C"
                except ValueError:
                    cputmp = "xx"

            case "Darwin":
                # bc MacOS doesn't let psutil see core temps
                # git@github.com:narugit/smctemp.git
                ran = subprocess.run('smctemp -c', shell=True, text=True, capture_output=True)
                cputmp = f"{int(round(float(ran.stdout), 0))}°C"
                # line += '"cputemp": "' + cputmp + '"}\n'

            case other:
                raise NotImplementedError(f"what os? {platform.system()}")

        outputs["cputemp"] = cputmp


        with open(STATEJSON, "wt") as f:
            f.write(f"{json.dumps(outputs, sort_keys=True, indent=4)}\n")

        time.sleep(1)


def only_me():
    # TODO: what happens if connectivity breaks? what does the tty report in ps Ax?
    ws = re.compile(r'\s+')

    ran = subprocess.run("ps Ax".split(' '), capture_output=True, text=True)
    lines = ran.stdout.split('\n')

    ttys = [ws.split(line) for line in lines
            if 'bash' in line and 'wezterm-escapes' in line and 'tty' in line]

    # if the second field is "??" there's no controlling terminal and can kill
    # we don't want to run wezterm-escapes in defunct ttys
    for row in [r for r in ttys if r[1] == "??"]:
        os.kill(int(row[0]), signal.SIGKILL)

    # only one process of this script is allowed, so we SIGHUP the running one(s)
    pids = {int(ws.split(row)[0]) for row in lines
            if 'python' in row and 'wezterm-record.py' in row} - {os.getpid()}

    for pid in pids:
        os.kill(pid, signal.SIGHUP)



if __name__ == "__main__":
    STATEFILE.parent.mkdir(parents=True, exist_ok=True)
    only_me()
    main()

# done
