---
name: gh-ops
description: "This skill should be used when the user asks to 'check PR comments', 'PRのコメント確認', 'review PR feedback', 'get review comments', 'レビューコメント取得', 'check CI logs', 'CI確認', 'check GitHub Actions', 'why did CI fail', 'CIなぜ落ちた', or needs to retrieve PR review comments or GitHub Actions run logs using gh CLI."
allowed-tools: Read
version: 0.1.0
---

# gh-ops

## スクリプトによる操作（推奨）

ラッパースクリプトを使う。正しいエンドポイント・`--paginate`・`--jq` が自動適用され、GET のみに制限される。

### PR コメント取得

```bash
# review comments 一覧
${CLAUDE_PLUGIN_ROOT}/scripts/pr-comments.sh owner/repo 123

# 会話欄コメント（issue comments）
${CLAUDE_PLUGIN_ROOT}/scripts/pr-comments.sh owner/repo 123 --conversation

# 個別の review comment（PR番号不要）
${CLAUDE_PLUGIN_ROOT}/scripts/pr-comments.sh owner/repo --id 456789

# 特定ユーザーでフィルタ
${CLAUDE_PLUGIN_ROOT}/scripts/pr-comments.sh owner/repo 123 --user hazi

# 特定ファイルでフィルタ
${CLAUDE_PLUGIN_ROOT}/scripts/pr-comments.sh owner/repo 123 --file src/main.rs
```

出力: `{id, path, body(1500文字), user, line}` の JSON 配列

### Actions ログ取得

```bash
# 最近の run 一覧（デフォルト5件）
${CLAUDE_PLUGIN_ROOT}/scripts/run-logs.sh owner/repo

# カレントリポジトリの run 一覧（owner/repo 省略可）
${CLAUDE_PLUGIN_ROOT}/scripts/run-logs.sh

# 特定 run の失敗ログ
${CLAUDE_PLUGIN_ROOT}/scripts/run-logs.sh owner/repo --run-id 12345

# 全ログ（出力が大きい）
${CLAUDE_PLUGIN_ROOT}/scripts/run-logs.sh owner/repo --run-id 12345 --full

# ブランチ・ワークフローでフィルタ
${CLAUDE_PLUGIN_ROOT}/scripts/run-logs.sh owner/repo --branch main --limit 10
${CLAUDE_PLUGIN_ROOT}/scripts/run-logs.sh owner/repo --workflow ci.yml
```

---

## 生 gh api を使う場合の注意

スクリプトでカバーできないケース（reviews 一覧、PR files 一覧など）は直接 `gh api` を使う。

### 必須ルール

1. **`--paginate` を常に付ける** — GitHub API は1ページ30件。省略すると取得漏れする
2. **`--jq` を使う。`| jq` は禁止** — `--jq` は gh 内部でフィルタし stdout が小さい。`| jq` は全レスポンスが流れ truncate される
3. **MCP ツールが使える場合はそちらを優先** — `pull_request_read` 等は認証・ページネーションを自動処理

エンドポイント詳細は `${CLAUDE_PLUGIN_ROOT}/skills/gh-ops/references/endpoints.md` を参照。

---

## やってはいけないパターンまとめ

| パターン                               | 問題                | 正しい方法            |
| -------------------------------------- | ------------------- | --------------------- |
| `pulls/{number}/comments/{id}`         | 404                 | `pulls/comments/{id}` |
| `\| jq` でパイプ                       | 出力過大で truncate | `--jq` オプション     |
| `contains()` を数値/オブジェクトに使用 | jq 型エラー         | `==` か `test()`      |
| `gh run view --log` を最初に試す       | 出力が巨大          | `--log-failed` を先に |
