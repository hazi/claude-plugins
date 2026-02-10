#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions run 一覧取得・ログ取得ラッパー（読み取り専用）
# Usage: run-logs.sh [<owner/repo>] [options]

usage() {
  cat <<'EOF'
Usage: run-logs.sh [<owner/repo>] [options]

Options:
  --run-id <id>         特定の run のログを取得
  --branch <branch>     ブランチでフィルタ
  --workflow <name>     ワークフローでフィルタ
  --limit <n>           一覧の件数（default: 5）
  --full                全ログ取得（デフォルトは --log-failed）
  -h, --help            このヘルプを表示
EOF
  exit "${1:-0}"
}

# --- 引数パース ---
REPO=""
RUN_ID=""
BRANCH=""
WORKFLOW=""
LIMIT=5
FULL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      [[ $# -lt 2 ]] && { echo "Error: --run-id には値が必要です" >&2; exit 1; }
      RUN_ID="$2"
      shift 2
      ;;
    --branch)
      [[ $# -lt 2 ]] && { echo "Error: --branch には値が必要です" >&2; exit 1; }
      BRANCH="$2"
      shift 2
      ;;
    --workflow)
      [[ $# -lt 2 ]] && { echo "Error: --workflow には値が必要です" >&2; exit 1; }
      WORKFLOW="$2"
      shift 2
      ;;
    --limit)
      [[ $# -lt 2 ]] && { echo "Error: --limit には値が必要です" >&2; exit 1; }
      LIMIT="$2"
      shift 2
      ;;
    --full)
      FULL=true
      shift
      ;;
    -h|--help)
      usage 0
      ;;
    -*)
      echo "Error: 不明なオプション: $1" >&2
      usage 1
      ;;
    *)
      # owner/repo として扱う
      if [[ -z "$REPO" ]]; then
        REPO="$1"
      else
        echo "Error: 不明な引数: $1" >&2
        usage 1
      fi
      shift
      ;;
  esac
done

# リポジトリ自動検出
if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null) || {
    echo "Error: リポジトリを指定するか、Git リポジトリ内で実行してください" >&2
    exit 1
  }
fi

# owner/repo の形式チェック
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
  echo "Error: リポジトリは owner/repo 形式で指定してください: $REPO" >&2
  exit 1
fi

# --- 実行 ---

if [[ -n "$RUN_ID" ]]; then
  # 特定 run のログ取得
  if [[ "$FULL" == true ]]; then
    gh run view "$RUN_ID" --repo "$REPO" --log
  else
    gh run view "$RUN_ID" --repo "$REPO" --log-failed
  fi
else
  # run 一覧
  ARGS=(--repo "$REPO" --limit "$LIMIT")
  if [[ -n "$BRANCH" ]]; then
    ARGS+=(--branch "$BRANCH")
  fi
  if [[ -n "$WORKFLOW" ]]; then
    ARGS+=(--workflow "$WORKFLOW")
  fi
  gh run list "${ARGS[@]}"
fi
