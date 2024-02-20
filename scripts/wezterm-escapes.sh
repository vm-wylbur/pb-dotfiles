#!/bin/bash
# TODO: any way to know what pty we're in? or have we been disowned?
while true; do
    pkddata=$(cat ~/.local/state/wezterm.json | base64 --wrap=0)
    printf "\033]1337;SetUserVar=%s=%s\007" "pkd" ${pkddata}
    sleep 1
done

# done.
