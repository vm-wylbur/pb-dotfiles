#!/bin/bash

while true; do
    pkddata=$(cat ~/.local/state/wezterm | base64 --wrap=0)
    printf "\033]1337;SetUserVar=%s=%s\007" "pkd" "${pkddata}"
    sleep 1
done

# done.
