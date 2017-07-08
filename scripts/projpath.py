#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Authors:     PB
# Maintainers: PB
# Copyright:   2017, HRDAG, GPL v2 or later
# ============================================
# dotfiles/scripts/projpath.py
# inserted with :r !projpath.py %  
# could be integrated into a snippet? 
# 
import os.path
import collections
import sys

startpath = os.path.realpath(sys.argv[1])
original_startpath = startpath
rstack = collections.deque()
while True:

    lpart, rpart = os.path.dirname(startpath), os.path.basename(startpath)
    rstack.appendleft(rpart)

    if lpart == '/':
        raise OSError("no git dir found in {}.".format(original_startpath))
    subdirs = next(os.walk(lpart))[1]
    if '.git' in subdirs:
        rpart = os.path.basename(lpart)
        rstack.appendleft(rpart)
        break
    startpath = lpart

print('# ' + os.path.join(*rstack))

# done
