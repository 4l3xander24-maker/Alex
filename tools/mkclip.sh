#!/bin/bash
# uso: mkclip.sh nombre inicio duracion   -> docs/promo/clips/<nombre>-alto.mp4 (720x1280) y -ancho.mp4 (1280x614), y borra el original
n=$1; ss=$2; d=$3; O=/Users/alex/Proyectos/ROBLOX/docs/promo/clips
ffmpeg -y -loglevel error -ss $ss -t $d -i /tmp/raw_$n.mov -vf "crop=688:1224:1044:390,scale=720:1280:flags=lanczos,fps=30" -an -c:v libx264 -crf 26 -preset slow -pix_fmt yuv420p -movflags +faststart $O/$n-alto.mp4
ffmpeg -y -loglevel error -ss $ss -t $d -i /tmp/raw_$n.mov -vf "crop=2550:1224:113:390,scale=1280:614:flags=lanczos,fps=30" -an -c:v libx264 -crf 26 -preset slow -pix_fmt yuv420p -movflags +faststart $O/$n-ancho.mp4
rm -f /tmp/raw_$n.mov
ls -la $O/$n-*.mp4 | awk '{print $5/1e6" MB", $9}'
