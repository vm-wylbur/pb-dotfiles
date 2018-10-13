#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Authors:     PB
# Maintainers: PB
# Copyright:   2018, HRDAG, GPL v2 or later
# ============================================
# dotfiles/scripts/projpath.py
# inserted with :r !projpath.py %
# could be integrated into a snippet?
#
import os.path
import os
import collections
import sys


def projpath(startpath):
    original_startpath = startpath
    rstack = collections.deque()
    while True:

        lpart, rpart = os.path.dirname(startpath), os.path.basename(startpath)
        rstack.appendleft(rpart)

        if lpart == '/':
            print('')
            sys.exit(1)
            # raise OSError("no git dir found in {}.".format(original_startpath))

        subdirs = next(os.walk(lpart))[1]
        if '.git' in subdirs:
            rpart = os.path.basename(lpart)
            rstack.appendleft(rpart)
            break
        startpath = lpart

    return os.path.join(*rstack)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        startpath = os.path.realpath(sys.argv[1])
    else:
        startpath = os.getcwd()
    print(projpath(startpath))
# done
