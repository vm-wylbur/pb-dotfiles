#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Author: PB
# Maintainer(s): PB
# License: (c) HRDAG 2018, GPL v2 or newer
#
# filename: dotfiles/scripts/snippet_helper/snippet_helper/__init__.py
#
# -----------------------------------------------------------
#
import git
import os.path

def projpath(fpath):
    fpath = os.path.expanduser(fpath)
    fpath = os.path.abspath(fpath)
    git_repo = git.Repo(fpath, search_parent_directories=True)
    git_root = git_repo.git.rev_parse("--show-toplevel")
    assert not git_root.endswith('/')
    len_local_path = len(os.path.split(git_root)[0]) + 1
    project_path = fpath[len_local_path:]
    return project_path

# done.
