#!/usr/bin/env bash
set -euo pipefail

# PR コメント取得ラッパー（読み取り専用）
# Usage: pr-comments.sh <owner/repo> <pr_number> [options]
#        pr-comments.sh <owner/repo> --id <comment_id>

usage() {
  cat <<'EOF'
Usage: pr-comments.sh <owner/repo> <pr_number> [options]
       pr-comments.sh <owner/repo> --id <comment_id>

Options:
  --id <comment_id>     個別の review comment を取得（PR番号不要）
  --conversation        会話欄コメント（issue comments）を取得
  --user <login>        特定ユーザーでフィルタ
  --file <path>         特定ファイルでフィルタ
  -h, --help            このヘルプを表示
EOF
  exit "${1:-0}"
}

# --- 引数パース ---
REPO=""
PR_NUMBER=""
COMMENT_ID=""
CONVERSATION=false
FILTER_USER=""
FILTER_FILE=""

[[ $# -eq 0 ]] && usage 1

# 最初の引数が -h/--help ならヘルプ表示
[[ "$1" == "-h" || "$1" == "--help" ]] && usage 0

REPO="$1"
shift

# owner/repo の形式チェック
if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
  echo "Error: リポジトリは owner/repo 形式で指定してください: $REPO" >&2
  exit 1
fi

# 2番目の引数がオプションでなければ PR 番号
if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
  PR_NUMBER="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      [[ $# -lt 2 ]] && { echo "Error: --id には値が必要です" >&2; exit 1; }
      COMMENT_ID="$2"
      shift 2
      ;;
    --conversation)
      CONVERSATION=true
      shift
      ;;
    --user)
      [[ $# -lt 2 ]] && { echo "Error: --user には値が必要です" >&2; exit 1; }
      FILTER_USER="$2"
      shift 2
      ;;
    --file)
      [[ $# -lt 2 ]] && { echo "Error: --file には値が必要です" >&2; exit 1; }
      FILTER_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage 0
      ;;
    *)
      echo "Error: 不明なオプション: $1" >&2
      usage 1
      ;;
  esac
done

# --- 実行 ---

# 個別 comment 取得
if [[ -n "$COMMENT_ID" ]]; then
  gh api "repos/${REPO}/pulls/comments/${COMMENT_ID}" \
    --jq '{id, path, body: .body[:1500], user: .user.login, line}'
  exit 0
fi

# PR 番号必須チェック
if [[ -z "$PR_NUMBER" ]]; then
  echo "Error: PR 番号を指定してください（--id を使う場合は PR 番号不要）" >&2
  usage 1
fi

# jq フィルタ組み立て
build_jq_filter() {
  local select_clauses=()
  local fields="$1"

  if [[ -n "$FILTER_USER" ]]; then
    select_clauses+=("select(.user.login == \"${FILTER_USER}\")")
  fi
  if [[ -n "$FILTER_FILE" ]]; then
    select_clauses+=("select(.path == \"${FILTER_FILE}\")")
  fi

  local pipeline=".[]"
  for clause in "${select_clauses[@]}"; do
    pipeline="${pipeline} | ${clause}"
  done
  pipeline="${pipeline} | ${fields}"

  echo "[${pipeline}]"
}

if [[ "$CONVERSATION" == true ]]; then
  # issue comments（会話欄）
  JQ_FILTER=$(build_jq_filter '{id, body: .body[:1500], user: .user.login, created_at}')
  gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --paginate \
    --jq "$JQ_FILTER"
else
  # review comments
  JQ_FILTER=$(build_jq_filter '{id, path, body: .body[:1500], user: .user.login, line}')
  gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments" \
    --paginate \
    --jq "$JQ_FILTER"
fi
