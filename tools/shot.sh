#!/bin/bash
# Captura el viewport de Roblox Studio en alta resolución (solo la ventana de
# Studio, aunque tenga otra encima) y lo recorta a 16:9 sin los iconos de la
# esquina. Uso: tools/shot.sh nombre
out="/Users/alex/Proyectos/ROBLOX/docs/promo/$1.png"
id=$(/tmp/wid | awk 'NR==1{print $1}')
screencapture -x -o -l "$id" /tmp/_full.png
sips -c 1129 2008 --cropOffset 398 160 /tmp/_full.png --out "$out" >/dev/null 2>&1
sips -g pixelWidth -g pixelHeight "$out" | tail -2
