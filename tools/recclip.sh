#!/bin/bash
# uso: recclip.sh nombre segundos
id=$(/tmp/wid | grep -E "Footage" | awk '{print $1}')
screencapture -x -v -V $2 -l $id /tmp/raw_$1.mov
