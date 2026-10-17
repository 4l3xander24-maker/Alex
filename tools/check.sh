#!/bin/bash
# Revisión rápida antes de subir cambios: analiza el código de la Partida y del
# Lobby con luau-lsp y corre el modelo de balance. Uso: bash tools/check.sh <carpeta con globalTypes.d.luau>
set -e
DEFS="${1:?Pasa la carpeta donde está globalTypes.d.luau}"
cd "$(dirname "$0")/.."
~/.rokit/bin/rojo sourcemap default.project.json -o "$DEFS/sourcemap.json" > /dev/null
~/.rokit/bin/luau-lsp analyze --sourcemap="$DEFS/sourcemap.json" --definitions="$DEFS/globalTypes.d.luau" src/server src/shared src/client 2>&1 | grep -v "INFO\|WARN\] client" || true
~/.rokit/bin/rojo sourcemap lobby.project.json -o "$DEFS/sm_lobby.json" > /dev/null
~/.rokit/bin/luau-lsp analyze --sourcemap="$DEFS/sm_lobby.json" --definitions="$DEFS/globalTypes.d.luau" src/lobby src/shared 2>&1 | grep -v "INFO\|WARN\] client" || true
python3 tools/balance.py
