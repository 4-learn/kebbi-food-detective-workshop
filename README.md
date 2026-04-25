# Kebbi Food Detective — Workshop（教師工具箱）

> 「凱比的食物偵探大冒險」5 天課程的**老師端**全套工具：
> 自動 provisioning 12 個學生工作區、tmux session 管理、簡報自動上傳 HackMD、Ch4 教師解答 prompt。

📚 **公開版 demo（學生看的）**：[`4-learn/kebbi-food-detective-demo`](https://github.com/4-learn/kebbi-food-detective-demo)
🔒 **這個 repo（teacher only，private）**：含教師解答 prompt + 提示階梯 + 課堂自動化

---

## 目錄結構

```
.
├── README.md                  ← 你正在看
├── .gitignore                 ← 排除 secrets + 學生工作區 + build artifacts
├── provision-group.sh         ← 一鍵建一組 g{N}（rsync teacher template + 改 package + 起 tmux + codex）
├── restore-tmux.sh            ← Reboot 後重建所有 tmux session
├── upload-slides.py           ← Ch5 codex 自動上傳簡報到 HackMD 大集合
├── provision-student.sh       ← Ch3 era（個人組）— 不在 Ch4 用
├── bootstrap-students.sh      ← Ch3 era（一鍵 provision 多人）— 不在 Ch4 用
└── teacher/                   ← teacher template Android project + Ch4 教師解答
    ├── AGENTS.md              ← 給 codex 看的，含 Ch3+Ch4+Ch5 全套指令對應
    ├── README.md
    ├── app/                   ← Android Kotlin source (WebView 殼，cc.fourimpact.allergy.steacher)
    ├── build.gradle.kts、settings.gradle.kts、gradle/、gradlew*
    └── prompts/
        └── teacher.txt        ← 🎓 Ch4 教師解答（Dr. 凱比博士 1341 bytes）
```

**不進 git 的東西**（`.gitignore` 把關）：
- `g0/`〜`g11/` — 學生工作區，從 `teacher/` 用 `provision-group.sh` 生
- `.openai/`、`.liyu/`、`.hackmd/`、`.rclone/` — API tokens
- `**/build/`、`**/.gradle/`、`local.properties` — Android build 暫存
- `*.bak.*` — main.py 的時間戳備份

---

## Reboot 後 5 秒回復現場

```bash
bash restore-tmux.sh
```
13 個 tmux session（teacher + g0〜g11，將擴 g12〜g15）全部回來，每個內跑 `codex --dangerously-bypass-approvals-and-sandbox`。

## 開新組

```bash
bash provision-group.sh <0..15>
```

## 學生在 tmux liyu-g{N} 對 codex 說「幫我做簡報」會發生

1. codex 讀 `prompts/g{N}.txt` 看實際許願
2. 產 `slides/g{N}.md`（含 slideOptions frontmatter，≤ 6 張）
3. 自動 `python3 ../upload-slides.py g{N} slides/g{N}.md`
4. POST 新 HackMD note + PATCH 簡報大集合 append 連結

## Ch4 教師解答（這個 repo 的私有資產）

- 完整 prompt 在 `teacher/prompts/teacher.txt`（1341 bytes）
- 也是 GCP backend 的 `DEFAULT_SYSTEM_PROMPT`（見 `4-learn/kebbi-food-detective-demo` repo 的 `main.py`）
- 詳細 before/after 實測 + 3 級提示階梯：HackMD `HkTUFWtT-l`（owner private）

---

## 環境前置

詳見 4-learn VM 上 `~/workspace/liyu/codex/` 對應的 memory 檔案：
- toolchain（JDK 17、Android SDK、gradle）：`/etc/profile.d/android.sh` 自動 export
- API tokens：`.openai/`、`.liyu/`、`.hackmd/`、`.rclone/`（皆 chmod 600）

## 課程文件（HackMD）

| 章節 / 文件 | Alias | 視角 |
|---|---|---|
| 課綱 | `r1fSmRkq-l` | guest |
| Ch3 | `rylX7Akcbl` | guest |
| Ch4 學生版 | `Hy77XR1qWx` | guest |
| Ch5 學生版 | `Skp7mRyqbe` | guest |
| Ch5 示範簡報 | `HJPcPqtTZe` | guest |
| Ch5 簡報大集合 | `Hy-okxqT-l` | guest |
| Ch4 教師解答 | `HkTUFWtT-l` | 🔒 owner |

---

🔒 **這個 repo 是 private**——含教師解答，公開會破壞下一屆學生 Ch4 的「自己探索」教學意圖。
