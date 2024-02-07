#!/usr/bin/env python3
# set expandtab ts=4 sw=4 ai fileencoding=utf-8
#
# Author: PB
# Maintainer(s): PB
# License: (c) HRDAG 2019, GPL v2 or newer
#
# -----------------------------------------------------------
# archiver/bin/getpix.py

import argparse
import os
import re
import shutil
import datetime
from subprocess import Popen, PIPE, run
import collections
import uuid
import sys
from pathlib import Path


date_re = re.compile(r'Masters/(\d{4}/\d{2}/\d{2})')
photo_exts = {'.cr2', '.nef', '.raf', '.jpg', '.jpeg', '.rw2', '.tif',
              '.tiff', '.mov', '.mp4'}
splt = re.compile(r'Image timestamp : ')
fnsanitizer = re.compile(r'\s+|\(|\)|,|:')
cnts = collections.defaultdict(int)


def getargs():
    parser = argparse.ArgumentParser(description="copies image files from a"
                                     " source directory into a "
                                     " bydate/YYYY/MM/DD structure,"
                                     " preserving the EXIF date when possible."
                                     " Depends on gnu find and exiv2 on path.")
    parser.add_argument("--verbose", '-v', action='store_true')
    parser.add_argument("source", nargs=1)
    parser.add_argument("destination", nargs=1)
    return parser.parse_args()


def _now():
    return datetime.datetime.now().isoformat()[0:19]


def get_exif_ts_dir(dpath):
    def _linesp(line):
        pth, ts = [s.strip() for s in splt.split(line)]
        pth = Path(pth).name
        ts = ts[0:10].replace(":", "/")
        return pth, ts

    dpath = str(Path(dpath).resolve())
    with open(os.devnull, 'w') as FNULL:
        stdopts = {'stdout': PIPE, 'stderr': FNULL}
        findcmd = ['find', dpath, '-maxdepth', '1', '-type', 'f', '-print0']
        # TODO: filter findcmd to exclude files with 'preview' in the filename
        # they're noise. 
        ps1 = Popen(findcmd, **stdopts)
        ps2 = Popen(['xargs', '-0', 'exiv2'], stdin=ps1.stdout, **stdopts)

        runopts = {'stdin': ps2.stdout, 'capture_output': True}
        result = run(['grep', 'timestamp'], **runopts)
    if result.returncode != 0:
        return dict()
    lines = filter(None, result.stdout.decode('utf-8').split('\n'))
    return dict(_linesp(x) for x in lines)


def date_from_pth(pth):
    s = date_re.search(str(pth))
    if s:
        filedatepart = s.groups()[0]
        cnts['date from ap path'] += 1
    else:
        filedatepart = 'no_date'
        cnts['no_date'] += 1
    return filedatepart


def well_formed_dt(d):
    dp = d.split('/')
    try:
        year = int(dp[0])
    except ValueError:
        return 'no_date'
    if year < 1900 or 2020 < year:
        return 'no_date'
    elif len(dp) == 3:
        pass
    elif len(dp) == 2:
        dp.append('01')
    elif len(dp) == 1:
        dp.extend(['01', '01'])
    else:
        return 'no_date'
    dp[1] = dp[1].rjust(2, '0')
    dp[2] = dp[2].rjust(2, '0')
    dp = '/'.join(dp)
    return dp


if __name__ == '__main__':
    args = getargs()
    dstroot = Path(args.destination[0]).resolve()
    assert dstroot.parts[-1] == 'bydate'

    print(f"start {_now()}")
    dirpath = Path(args.source[0]).resolve()

    for dirpath, dirs, files in os.walk(dirpath):
        rpth = Path(dirpath)
        name2ts = get_exif_ts_dir(dirpath)

        for f in files:
            pth = rpth / f
            suff = pth.suffix.strip().lower()
            if suff not in photo_exts:
                cnts['suffix not found'] += 1
                continue

            filedatepart = name2ts.get(f, None)
            if filedatepart is None:
                filedatepart = date_from_pth(pth)
                cpsym = '-'
            else:
                cpsym = '='

            filedatepart = well_formed_dt(filedatepart)
            fname = fnsanitizer.sub('_', f)
            dst = dstroot / filedatepart / fname
            try:
                dstat = dst.stat()
            except FileNotFoundError:
                dstat = None   # OK to write
            if dstat and pth.stat().st_size == dstat.st_size:
                cnts['found identical'] += 1
                continue
            elif dstat:
                fname = str(uuid.uuid4()) + pth.suffix.lower()
                dst = dstroot / filedatepart / fname
                cnts['renamed w uuid'] += 1

            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(pth, dst, follow_symlinks=False)
            if args.verbose:
                print(f"{pth} {cpsym}> {dst}")
            cnts['copied'] += 1

            if args.verbose and cnts['copied'] % 500 == 0:
                print(f"{_now()}: {dict(cnts)}.")

    now = datetime.datetime.now().isoformat()
    print(f"{_now()}: {dict(cnts)}. DONE.")

# done.
