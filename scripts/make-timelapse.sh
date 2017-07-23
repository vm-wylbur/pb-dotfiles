#!/bin/bash
f="$1"
gethour="$HOME/dotfiles/scripts/exif-gethour.py"
# START_NO=1726

# for f in `ls DSC_*.JPG`; do ~/dotfiles/scripts/make-timelapse.sh "$f" ; done

hr=$(exiv2 "$f" | $gethour)
convert "$f" -pointsize 128 -fill yellow \
  -gravity NorthWest -annotate +30+30 "$hr" "t-${f}"

# ffmpeg -start_number $START_NO -i DSC_%04d.JPG -c:v libx264 -pix_fmt yuv420p video.mp4
