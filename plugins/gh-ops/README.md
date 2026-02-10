# gh-ops

Claude Code 用の GitHub CLI 操作プラグイン。ラッパースクリプトで PR コメント取得・CI ログ確認を安全に実行する。

## 背景

Claude Code が `gh api` を直接使う際の問題を解決：

- `Bash(gh api:*)` を許可すると POST/DELETE も通ってしまう
- 間違ったエンドポイント・`| jq` パイプなどのミスが防げない

ラッパースクリプト経由にすることで、正しいエンドポイント・`--paginate`・`--jq` が強制され、GET のみに制限される。

## 使い方

```
/gh-ops
```

スキルがロードされ、スクリプト経由での安全な操作パターンが適用される。

## カバーする操作

- **PR review comments** -- 一覧取得、個別取得、ユーザー/ファイルフィルタ
- **PR issue comments** -- 会話欄コメントの取得
- **GitHub Actions** -- run 一覧、失敗ログ取得、ワークフロー/ブランチ指定

## 権限設定

スクリプト実行時に毎回確認ダイアログが出る。省略したい場合は `.claude/settings.json` の `permissions.allow` にスクリプトのパスを追加する。

```json
{
  "permissions": {
    "allow": [
      "Bash(/path/to/gh-ops/scripts/pr-comments.sh:*)",
      "Bash(/path/to/gh-ops/scripts/run-logs.sh:*)"
    ]
  }
}
```

`/path/to/gh-ops/` はプラグインの実際のインストールパスのフルパスに置き換える（`~` や `$HOME` は使用不可）。通常は `~/.claude/plugins/cache/hazi-plugins/gh-ops/0.1.0/` にインストールされる。スクリプトは GET のみなので書き込み操作の心配はない。
