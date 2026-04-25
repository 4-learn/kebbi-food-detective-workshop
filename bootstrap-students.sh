#!/usr/bin/env bash
# 把 codex/0 (golden sample) 一次性鋪到 codex/1..10
# 用法: bash bootstrap-students.sh
# 內部呼叫 provision-student.sh，所以新增/reset 邏輯都共用一份

set -euo pipefail

CODEX_DIR="$(cd "$(dirname "$0")" && pwd)"

for i in {1..10}; do
  bash "$CODEX_DIR/provision-student.sh" "$i"
done

echo
echo "All done. 11 student folders + 11 tmux sessions ready."
ls -d "$CODEX_DIR"/{0..10}
tmux ls | grep '^liyu-'
