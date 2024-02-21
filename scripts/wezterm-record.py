#!/usr/bin/env python3
import psutil
import subprocess
import itertools as it
import time
from datetime import datetime
from pathlib import Path
import json
import platform
import signal
import os
import re
from typing import Final

STATEFILE: Final[Path] = Path().home() / ".local/state/wezterm"
STATEJSON: Final[Path] = Path().home() / ".local/state/wezterm.json"
GIG: Final[float] = 1024*1024*1024.0


def roundgig(num: int | float) -> int:
    return int(round(num/GIG, 0))


def main() -> None:
    while True:
        ctp = psutil.cpu_percent(0.25)
        outputs = {"cpuusage": f"{ctp:>4}%"}

        dtime = int(datetime.now().strftime("%s"))
        outputs["timestamp"] = f"{dtime}"

        vm = psutil.virtual_memory()
        memfree = (f"{roundgig(vm.available)}/"
                   f"{roundgig(vm.total)}G")

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

        jsontxt = f"{json.dumps(outputs, sort_keys=True, indent=4)}\n"
        with open(STATEJSON, "wt") as f:
            f.write(jsontxt)

        time.sleep(1)


def only_me() -> None:
    # TODO: what happens if connectivity breaks? what does the tty report in ps Ax?
    ws = re.compile(r'\s+')

    ran = subprocess.run("ps ax".split(' '), capture_output=True, text=True)
    lines = ran.stdout.split('\n')
    rows = [tuple(ws.split(line)) for line in lines]

    escapes = it.filterfalse(lambda r: 'wezterm-escape' in r and 'running' in r, rows)
    # escapes = [r for r in rows if 'wezterm-escapes' in r and 'running' in r]
    # if the second field is "?" there's no controlling terminal and can kill
    # we don't want to run wezterm-escapes in defunct ttys
    e_pids = {int(row[0]) for row in escapes if '?' in row[1]}

    # only one process of this script is allowed, so we SIGHUP the running one(s)
    records = [r for r in rows if 'wezterm-record.py' in r and 'running' in r]
    r_pids = {int(row[0]) for row in records}

    pids = e_pids | r_pids - {os.getpid()}
    for pid in pids:
        os.kill(pid, signal.SIGHUP)


if __name__ == "__main__":
    STATEFILE.parent.mkdir(parents=True, exist_ok=True)
    only_me()
    main()

# done
