#!/bin/bash
set -e

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$PLUGIN_ROOT/node_modules" ] || \
   [ "$PLUGIN_ROOT/package.json" -nt "$PLUGIN_ROOT/node_modules/.package-lock.json" ]; then
  echo "Installing textlint dependencies..." >&2
  npm install --prefix "$PLUGIN_ROOT" --no-fund --no-audit 2>&2
fi
