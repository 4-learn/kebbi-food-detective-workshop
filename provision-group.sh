#!/usr/bin/env bash
# Provision/reset codex/g{N} from teacher template
# 用法: bash provision-group.sh <N>   N=0..11

set -euo pipefail

N="${1:?Usage: $0 <group-number 0..11>}"
[[ "$N" =~ ^([0-9]|1[0-1])$ ]] || { echo "ERROR: <N> 必須是 0..11，得到 '$N'" >&2; exit 1; }

CODEX_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$CODEX_DIR/teacher"
DST="$CODEX_DIR/g$N"

if [ ! -f "$SRC/gradlew" ]; then
  echo "ERROR: teacher template $SRC 不完整" >&2
  exit 1
fi

# 殺舊 tmux + 清舊資料夾
tmux kill-session -t "liyu-g$N" 2>/dev/null || true
rm -rf "$DST"
mkdir -p "$DST"

# rsync teacher（排除 prompts 資料夾，避免 teacher.txt 洩漏教師解答給學生）
rsync -a \
  --exclude='.gradle' --exclude='build' --exclude='app/build' --exclude='output' \
  --exclude='prompts' \
  "$SRC/" "$DST/"

# rename Kotlin package steacher → g{N}
mv "$DST/app/src/main/java/cc/fourimpact/allergy/steacher" \
   "$DST/app/src/main/java/cc/fourimpact/allergy/g$N"

# 改寫 package + label + URL
sed -i "s/cc\.fourimpact\.allergy\.steacher/cc.fourimpact.allergy.g$N/g" \
  "$DST/app/build.gradle.kts" \
  "$DST/app/src/main/java/cc/fourimpact/allergy/g$N/MainActivity.kt"
sed -i "s/TeacherApp/Group${N}App/g" \
  "$DST/settings.gradle.kts" \
  "$DST/app/src/main/res/values/strings.xml"

# MainActivity.kt URL 加上 ?group=g{N}
sed -i "s|\"https://allergy.4impact.cc\"|\"https://allergy.4impact.cc?group=g$N\"|g" \
  "$DST/app/src/main/java/cc/fourimpact/allergy/g$N/MainActivity.kt"

# 本地 prompts 副本
mkdir -p "$DST/prompts"
echo "You are a helpful assistant." > "$DST/prompts/g$N.txt"

# 寫 AGENTS.md（給 codex）
cat > "$DST/AGENTS.md" <<EOF
# Project Context for codex — Group $N

> Ch4 小組工作區（第 $N 組）。學生講口語，你對應到指令。

## 組別資訊
- group_id: \`g$N\`
- App 名稱: \`Group${N}App\`
- 本地 prompt 檔: \`./prompts/g$N.txt\`
- 後端 URL: \`\$LIYU_BASE_URL\`（環境變數已 export）
- 上傳認證: \`\$LIYU_API_KEY\`（環境變數已 export）

## 標準工作流（口語 → 你做的事）

| 學生口語 | 你要做的事 |
|---|---|
| 「改 prompt 讓 AI XXX」「修一下 prompt」 | ① 編輯 \`./prompts/g$N.txt\` ② **立刻**自動上傳到 server |
| 「上傳一下」「同步一下」 | \`curl -X POST -H "X-API-Key: \$LIYU_API_KEY" -H "Content-Type: text/plain" --data-binary @prompts/g$N.txt \$LIYU_BASE_URL/prompts/g$N\` |
| 「看一下現在的 prompt」 | \`curl -H "X-API-Key: \$LIYU_API_KEY" \$LIYU_BASE_URL/prompts/g$N\` |
| 「重 build APK」「重新打包」 | \`./gradlew assembleDebug\` → 複製到 \`output/Group${N}App.apk\` → \`rclone copy output/Group${N}App.apk gdrive:4-Learn/Ch4-AndroidApp/\` |

**規則**：每次改完 \`./prompts/g$N.txt\`，**立刻** POST 上傳，不要問「要不要上傳」，直接做完再回報。

## 4 個目標（這組要解全部）

| 代號 | 痛點 | 怎麼用 prompt 解 |
|---|---|---|
| **P1** | AI 答得隨便、沒結構 | system prompt 強制 3 段格式 |
| **P2** | AI 不特別提用戶選的過敏原 | system prompt 規定見「過敏原目標」要逐個警告 |
| **P3** | AI 模糊照硬猜、沒分風險 | system prompt 教 AI 用 🔴/🟡/🟢 標風險、不確定要說「請重拍」 |
| **P4** | AI 講話冷冰冰 | system prompt 設友善人格 + emoji + 鼓勵 |

## 環境
- JDK 17 + Android SDK + gradle 都備齊
- rclone config 在 \`../.rclone/rclone.conf\`，\`RCLONE_CONFIG\` 已設

## 卡住怎辦
- 上傳失敗 → \`echo \$LIYU_API_KEY\` 檢查環境變數
- AI 沒變 → 凱比 App 要**下拉重整或退出再進**
- 不確定 → 跟學生說「我不確定，去問老師」

---

## Ch5 工作流：做簡報上台

### 簡報上傳工具
- 大集合頁：https://hackmd.io/@yillkid/Hy-okxqT-l
- 上傳 script：\`python3 ../upload-slides.py g$N slides/g$N.md\`
- 環境變數 \`HACKMD_API_TOKEN\` 已自動 export，不用學生輸入

### 指令對應

| 學生口語 | 你要做的事 |
|---|---|
| 「幫我做簡報」「幫我做投影片」 | ① 讀 \`./prompts/g$N.txt\` 看實際許願 ② 產 markdown 投影片到 \`./slides/g$N.md\`（最上面要有 slideOptions frontmatter）③ **立刻**呼叫 upload script |
| 「上傳簡報」「丟上 HackMD」「同步簡報」 | \`python3 ../upload-slides.py g$N slides/g$N.md\` |
| 「改簡報的 X 段」 | 編輯 \`./slides/g$N.md\` 對應段，再上傳 |

**規則**：每次改完 \`./slides/g$N.md\`，**立刻** 跑 upload-slides.py 同步。

### 簡報結構（5 段，4 分鐘）
1. 我們組做了什麼（20 秒）
2. Vibe Coding 體驗 + 工具是 OpenAI 的 codex（60 秒）
3. 我許了什麼願（讀 \`./prompts/g$N.txt\` 用實際內容）（90 秒）
4. 我學到的事（30 秒）
5. 「這份簡報是 codex 幫我做的喔！」（30 秒）

### slide markdown frontmatter（必加在最上面）

\`\`\`yaml
---
title: 第 $N 組簡報
slideOptions:
  theme: white
  transition: slide
---
\`\`\`

每張投影片用 \`---\` 分隔，總共 ≤ 6 張。
EOF

# 寫 README.md（給學生）
cat > "$DST/README.md" <<EOF
# 第 $N 組 — 讓 AI 越來越聰明

## 你們組的任務

教自己組的 AI 解決 **4 個問題**（P1〜P4）。
全部用「**改 prompt**」就好，**不用碰程式**。

| 編號 | 問題 | 我們要 AI 怎樣 |
|---|---|---|
| **P1** | AI 答得很亂，每次都不一樣 | 永遠用 3 段答：① 食物 ② 過敏原 ③ 危不危險 |
| **P2** | 我選了會對花生過敏，AI 卻沒提花生 | 看到我選的過敏原一定要**特別大聲警告** |
| **P3** | AI 看不清楚還亂講、沒分風險 | 模糊就說「請重拍」；看清楚的用 🔴 / 🟡 / 🟢 標 |
| **P4** | AI 講話像客服，冷冰冰 | 變身「Dr. 凱比博士」，用 emoji、會打招呼 |

## 工作流程（5 秒一輪 iterate）

1. 對 codex 講：「**請改 prompt 讓 AI [想要的行為]**」
2. codex 自動改 \`./prompts/g$N.txt\` + 上傳 server（你不用管）
3. 凱比上點 **Group${N}App** → **重整**（下拉或退出再進）
4. 看新版 AI → 不滿意？再回步驟 1

## 你們的 App

凱比 launcher 上叫 **Group${N}App** 的就是你們組的。

## 驗收 checklist（自己跑過再交件）

每組要全部打勾才能上台 demo。

| P1 自驗 | P2 自驗 | P3 自驗 | P4 自驗 |
|---|---|---|---|
| □ 隨便拍 1 張，回答有 3 段 | □ 選花生 + 拍花生酥 → 有「⚠️ 花生」 | □ 拍模糊照 → AI 說「不確定」 | □ 第 1 句有自我介紹 |
| □ 連測 3 次都同樣格式 | □ 不選過敏原 + 拍同張 → 不強調花生 | □ 拍清楚 → 標 🔴 / 🟡 / 🟢 | □ 至少 1 個 emoji |
| □ 不囉嗦，不超過 3 行 | □ 選海鮮 + 拍蝦 → 有「⚠️ 海鮮」 | □ 拍非食物 → 不亂答 | □ 至少 1 句鼓勵語 |

## 卡住怎辦？三步驟

\`\`\`
1. 看清楚錯誤訊息
2. 整段複製，貼回給 codex
3. codex 會自己看怎麼修
\`\`\`

不要關 terminal、不要慌。
還是不會 → **舉手叫老師**。

## 加碼挑戰（4 個都打勾後可挑戰）

- 教 AI 用注音文回答
- 教 AI 用「從前從前有一顆花生…」故事體
- 教 AI 一張照片裡有多個食物時，每個都評
- 教 AI 拒絕跟食物無關的問題（例如有人問「你會打籃球嗎」）
EOF

# 加進 codex 信任清單
if ! grep -q "codex/g$N" ~/.codex/config.toml 2>/dev/null; then
  cat >> ~/.codex/config.toml <<EOF

[projects."$DST"]
trust_level = "trusted"
EOF
fi

# 開 tmux session 自動 codex
tmux new-session -d -s "liyu-g$N" -c "$DST" "bash -lc 'codex --dangerously-bypass-approvals-and-sandbox; exec bash'"

echo "✓ codex/g$N provisioned; tmux 'liyu-g$N' attached"
