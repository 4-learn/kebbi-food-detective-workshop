#!/usr/bin/env bash
# Provision (add or reset) codex/N to clean template + ensure tmux liyu-N
# 用法: bash provision-student.sh <N>
# 既能新增（codex/N 不存在），也能 reset（覆蓋現有的）

set -euo pipefail

N="${1:?Usage: $0 <student-number>}"
[[ "$N" =~ ^[0-9]+$ ]] || { echo "ERROR: <N> 必須是數字，得到 '$N'" >&2; exit 1; }

CODEX_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$CODEX_DIR/0"
DST="$CODEX_DIR/$N"

if [ ! -f "$SRC/gradlew" ]; then
  echo "ERROR: golden sample $SRC 不完整（缺 gradlew）" >&2
  exit 1
fi

if [ "$N" = "0" ]; then
  echo "ERROR: 不能 provision N=0（那是 golden sample）" >&2
  exit 1
fi

# 1. 殺掉現有 tmux session（如果在）
tmux kill-session -t "liyu-$N" 2>/dev/null || true

# 2. 清掉舊資料夾
rm -rf "$DST"
mkdir -p "$DST"

# 3. 從 golden sample rsync（排除 build/cache）
rsync -a \
  --exclude='.gradle' \
  --exclude='build' \
  --exclude='app/build' \
  --exclude='output' \
  "$SRC/" "$DST/"

# 4. rename Kotlin package 目錄 s0 -> sN
mv "$DST/app/src/main/java/cc/fourimpact/allergy/s0" \
   "$DST/app/src/main/java/cc/fourimpact/allergy/s$N"

# 5. 改寫 package / namespace
sed -i "s/cc\.fourimpact\.allergy\.s0/cc.fourimpact.allergy.s$N/g" \
  "$DST/app/build.gradle.kts" \
  "$DST/app/src/main/java/cc/fourimpact/allergy/s$N/MainActivity.kt"

# 6. 改寫 label / app_name / 學生編號（README + AGENTS.md）
sed -i "s/Student0App/Student${N}App/g" \
  "$DST/settings.gradle.kts" \
  "$DST/app/src/main/res/values/strings.xml" \
  "$DST/README.md" \
  "$DST/AGENTS.md"
sed -i "s/cc\.fourimpact\.allergy\.s0/cc.fourimpact.allergy.s$N/g" "$DST/AGENTS.md"
sed -i "s/Student 0/Student ${N}/g; s/學生編號：0/學生編號：${N}/g" \
  "$DST/README.md" "$DST/AGENTS.md"

# 7. 開新 tmux session（cwd 在學生資料夾，自動啟動 codex；codex 退出時 fallback 到 bash）
tmux new-session -d -s "liyu-$N" -c "$DST" \
  "bash -lc 'codex; exec bash'"

echo "✓ codex/$N provisioned; tmux session 'liyu-$N' attached at $DST"
