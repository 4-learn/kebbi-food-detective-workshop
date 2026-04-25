#!/usr/bin/env bash
# Reboot 後一鍵重建 Ch4 課堂用的 tmux sessions
# 不會動 codex/g{N} 內的檔案，只重啟 tmux + 自動拉 codex
# 用法：bash restore-tmux.sh

set -euo pipefail

CODEX_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== 重建 5 個 Ch4 tmux session ==="
for g in $(cd "$CODEX_DIR" && ls -d g[0-9] g1[0-1] teacher 2>/dev/null); do
  if [ ! -d "$CODEX_DIR/$g" ]; then
    echo "✗ $CODEX_DIR/$g 不存在，跳過"
    continue
  fi
  tmux kill-session -t "liyu-$g" 2>/dev/null || true
  tmux new-session -d -s "liyu-$g" -c "$CODEX_DIR/$g" "bash -lc 'codex --dangerously-bypass-approvals-and-sandbox; exec bash'"
  echo "✓ liyu-$g re-created"
done

sleep 8

echo
echo "=== 驗證 codex 都活著 ==="
for g in $(cd "$CODEX_DIR" && ls -d g[0-9] g1[0-1] teacher 2>/dev/null); do
  s=$(tmux capture-pane -p -t "liyu-$g" -S -200 2>/dev/null | grep -c "OpenAI Codex")
  printf "liyu-%-7s codex=%s\n" "$g" "$s"
done

echo
echo "Done. 學生可以 ssh ubuntu@4-learn + tmux attach -t liyu-g{N}"
