# Project Context for codex — Teacher（Ch3 + Ch4 unified）

> 這份檔案是給 **codex** 看的，告訴你這個專案的技術細節。
> 學生（小學生）會用口語說話，你要把口語對應到下面的指令。
> Teacher 是**講師白老鼠工作區**，用來在把流程推給 g1〜g4 之前先自己實驗。

## 專案類型

- Android Kotlin App（Gradle 8.7 + AGP 8.5.0）
- WebView 殼，載入 https://allergy.4impact.cc
- minSdk 24 / targetSdk 35
- Package: `cc.fourimpact.allergy.steacher`
- App 名稱：`TeacherApp`

---

## Ch3 工作流：打包 App

| 學生口語 | 你應該做的事 |
|---|---|
| 「幫我打包」「幫我建 App」「我要 APK」 | `./gradlew assembleDebug` |
| 「把 APK 整理出來」「我要拿 APK」 | `mkdir -p output && cp app/build/outputs/apk/debug/app-debug.apk output/TeacherApp.apk` |
| 「上傳到老師的雲端」「傳到 Drive」「交作業」 | `rclone copy output/TeacherApp.apk gdrive:4-Learn/Ch3-AndroidApp/` |
| 「全部弄好」「一條龍」「從頭到尾跑一次」 | 上面三個依序執行 |

### Ch3 加碼願望
- 「把 App 名字改成 X」 → 改 `app/src/main/res/values/strings.xml` 的 `app_name`，重新 build
- 「換成 X 顏色」 → 在 `res/values/themes.xml` 加色或改 status bar
- 「icon 換成 X 圖」 → 學生提供圖、放進 `app/src/main/res/mipmap-*` 或用 vector drawable

做完一樣 build + 上傳。

---

## Ch4 工作流：讓 AI 越來越聰明（改 prompt，不改 code）

### 組別資訊
- group_id: `teacher`
- 本地 prompt 檔: `./prompts/teacher.txt`
- 後端 URL: `$LIYU_BASE_URL`（環境變數已 export）
- 上傳認證: `$LIYU_API_KEY`（環境變數已 export）
- **測試用瀏覽器 URL**: `https://allergy.4impact.cc?group=teacher`
  （TeacherApp APK 本身沒帶 `?group=`，所以用瀏覽器打這個 URL 才看得到本組 prompt 的效果）

### 指令對應

| 學生口語 | 你要做的事 |
|---|---|
| 「改 prompt 讓 AI XXX」「修一下 prompt」 | ① 編輯 `./prompts/teacher.txt` ② **立刻**自動上傳到 server |
| 「上傳一下」「同步一下」 | `curl -X POST -H "X-API-Key: $LIYU_API_KEY" -H "Content-Type: text/plain" --data-binary @prompts/teacher.txt $LIYU_BASE_URL/prompts/teacher` |
| 「看一下現在的 prompt」 | `curl -H "X-API-Key: $LIYU_API_KEY" $LIYU_BASE_URL/prompts/teacher` |

**規則**：每次改完 `./prompts/teacher.txt`，**立刻** POST 上傳，不要問「要不要上傳」，直接做完再回報。

### AI 的執行環境（改 prompt 時記得考慮）

- **Model**: `gpt-4o-mini`（FastAPI backend `liyu/main.py` on GCP）
- **使用者訊息格式**（frontend `index.html` 在送 `/chat` 前組合）：
  ```
  過敏原目標：花生、海鮮（或「未選擇」）
  圖片：xxx.jpg（或「未上傳」）
  使用者問題：...
  ```
  實際圖片以 base64 data URL 另外由 `image_data_url` 欄位送進 AI。
- **AI 回覆顯示在凱比 WebView**，用純文字渲染（`textContent` + `white-space: pre-wrap`）：
  - ✅ 換行會保留
  - ✅ emoji 正常顯示（🔴 🟡 🟢 ⚠️ 等）
  - ❌ Markdown（`**bold**`、`## header`、`[link]()`）**不會渲染**，會變成字面符號
  - ❌ HTML 標籤（`<br>`、`<b>`）也不會渲染

### Ch4 的 4 個痛點（學生要解全部）

| 代號 | 學生會說 | prompt 解法方向 |
|---|---|---|
| **P1** | AI 答得隨便、沒結構 | system prompt 強制三段格式：① 食物 ② 過敏原 ③ 風險 |
| **P2** | 我選了花生過敏、AI 卻沒提花生 | system prompt 規定見「過敏原目標」要逐個檢查並警告 |
| **P3** | 模糊照硬猜、沒分風險 | system prompt 教 AI 不確定要說「請重拍」，清楚的用 🔴/🟡/🟢 標 |
| **P4** | AI 講話冷冰冰 | system prompt 設友善人格（Dr. 凱比博士）+ emoji + 鼓勵 |

---

## 環境

- JDK 17、Android SDK 在 `/opt/android-sdk`、env 已透過 `/etc/profile.d/android.sh` 設好
- Gradle 共用 cache 在 `/opt/gradle-cache`
- rclone 設定檔在 `../.rclone/rclone.conf`，`RCLONE_CONFIG` 已自動指過去 — 直接 `rclone copy ...` 就行
- Drive 資料夾：Ch3 上 `gdrive:4-Learn/Ch3-AndroidApp/`，Ch4 上 `gdrive:4-Learn/Ch4-AndroidApp/`

## 卡住怎辦

- compile 失敗 → 把 stack trace 給學生看，建議「貼回給我」就好
- rclone 失敗 → `rclone about gdrive:` 確認 token；token 過期 → 告訴老師重做 `rclone authorize`
- prompt 上傳失敗 → `echo $LIYU_API_KEY` 檢查環境變數
- AI 沒變 → 凱比 App / 瀏覽器要**下拉重整**或退出再進
- 任何超出此檔範圍的事 → 告訴學生「這個我不確定，去問老師」

---

## Ch5 工作流：做簡報上台

### 簡報上傳工具
- 大集合頁：https://hackmd.io/@yillkid/Hy-okxqT-l
- 上傳 script：`python3 ../upload-slides.py teacher slides/teacher.md`
- 環境變數 `HACKMD_API_TOKEN` 已自動 export，不用學生輸入

### 指令對應

| 學生口語 | 你要做的事 |
|---|---|
| 「幫我做簡報」「幫我做投影片」 | ① 讀 `./prompts/teacher.txt` 看實際許願 ② 產 markdown 投影片到 `./slides/teacher.md`（最上面要有 slideOptions frontmatter）③ **立刻**呼叫 upload script |
| 「上傳簡報」「丟上 HackMD」「同步簡報」 | `python3 ../upload-slides.py teacher slides/teacher.md` |
| 「改簡報的 X 段」 | 編輯 `./slides/teacher.md` 對應段，再上傳 |

**規則**：每次改完 `./slides/teacher.md`，**立刻** 跑 upload-slides.py 同步。

### 簡報結構（5 段，4 分鐘）
1. 我們組做了什麼（20 秒）
2. Vibe Coding 體驗 + 工具是 OpenAI 的 codex（60 秒）
3. 我許了什麼願（讀 `./prompts/teacher.txt` 用實際內容）（90 秒）
4. 我學到的事（30 秒）
5. 「這份簡報是 codex 幫我做的喔！」（30 秒）

### slide markdown frontmatter（必加在最上面）

```yaml
---
title: teacher 簡報
slideOptions:
  theme: white
  transition: slide
---
```

每張投影片用 `---` 分隔，總共 ≤ 6 張。
