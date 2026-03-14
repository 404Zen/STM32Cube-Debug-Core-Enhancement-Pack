#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import os

paths = [
    os.path.expanduser('~/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-jlink-gdbserver-1.2.0/package.json'),
    os.path.expanduser('~/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-stlink-gdbserver-1.2.0/package.json'),
    os.path.expanduser('~/.vscode/extensions/stmicroelectronics.stm32cube-ide-debug-core-1.2.0/package.json'),
]

for p in paths:
    print(f'=== {p}')
    if not os.path.exists(p):
        print('NOT FOUND')
        continue
    with open(p, 'r', encoding='utf-8') as f:
        pkg = json.load(f)
    print('name    =', pkg.get('name'))
    print('version =', pkg.get('version'))
    print('license =', pkg.get('license'))
    print()
PY
