# GitHub REST API エンドポイント逆引き表

## PR 関連エンドポイント

| 目的 | メソッド | エンドポイント |
|------|---------|---------------|
| PR 一覧 | GET | `repos/{owner}/{repo}/pulls` |
| PR 詳細 | GET | `repos/{owner}/{repo}/pulls/{number}` |
| PR review comments 一覧 | GET | `repos/{owner}/{repo}/pulls/{number}/comments` |
| PR review comment 個別 | GET | `repos/{owner}/{repo}/pulls/comments/{comment_id}` |
| PR issue comments 一覧 | GET | `repos/{owner}/{repo}/issues/{number}/comments` |
| PR reviews 一覧 | GET | `repos/{owner}/{repo}/pulls/{number}/reviews` |
| PR review 個別 | GET | `repos/{owner}/{repo}/pulls/{number}/reviews/{review_id}` |
| PR review のコメント | GET | `repos/{owner}/{repo}/pulls/{number}/reviews/{review_id}/comments` |
| PR files 一覧 | GET | `repos/{owner}/{repo}/pulls/{number}/files` |

### 注意: review comment の個別取得

```
# 正しい（PR 番号なし）
repos/{owner}/{repo}/pulls/comments/{comment_id}

# 間違い（404）
repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}
```

review comment の個別取得エンドポイントは PR 番号を含まない。これは GitHub API の仕様で、comment_id がリポジトリ内で一意だから。

---

## jq フィルタ テンプレート

### PR review comments

```bash
# 全コメントの概要
--jq '[.[] | {id, path, line: .line, body: .body[:100], user: .user.login}]'

# 特定ファイルのコメント
--jq '[.[] | select(.path == "src/main.rs") | {id, line: .line, body}]'

# 特定ユーザーのコメント
--jq '[.[] | select(.user.login == "reviewer") | {id, path, body}]'

# コメント数カウント
--jq 'length'

# ファイルごとのコメント数
--jq 'group_by(.path) | [.[] | {path: .[0].path, count: length}]'
```

### PR issue comments

```bash
# 全コメント概要
--jq '[.[] | {id, body: .body[:100], user: .user.login, created_at}]'

# bot 以外のコメント
--jq '[.[] | select(.user.type != "Bot") | {id, body: .body[:100], user: .user.login}]'
```

### PR reviews

```bash
# レビュー状態の確認
--jq '[.[] | {id, state, user: .user.login}]'

# CHANGES_REQUESTED のレビューだけ
--jq '[.[] | select(.state == "CHANGES_REQUESTED") | {id, body, user: .user.login}]'
```

### PR files

```bash
# 変更ファイル一覧
--jq '[.[] | {filename, status, additions, deletions}]'

# 特定拡張子の変更ファイル
--jq '[.[] | select(.filename | test("\\.rb$")) | {filename, status}]'
```

---

## jq 構文の注意点

### 文字列比較

```bash
# 完全一致: ==
select(.user.login == "hazi")

# 部分一致: test() （正規表現）
select(.user.login | test("ha"))

# 間違い: contains() は文字列同士なら動くが、型が違うとエラー
# select(.id | contains(123))  ← 数値に contains は使えない
```

### 文字列の切り詰め

```bash
# 先頭100文字
.body[:100]

# body が null の場合に備える
(.body // "")[:100]
```

### ページネーション

`gh api` には常に `--paginate` を付ける。GitHub API は1ページ30件しか返さないため、省略すると取得漏れする。

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments \
  --paginate \
  --jq '[.[] | {id, body: .body[:80], user: .user.login}]'
```

`--paginate` 使用時、`--jq` のフィルタは各ページに適用される。結果は改行区切りで連結される。配列として受け取りたい場合は後処理が必要。
