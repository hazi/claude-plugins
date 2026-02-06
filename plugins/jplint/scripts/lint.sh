#!/bin/bash
set -e

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEXTLINT="$PLUGIN_ROOT/node_modules/.bin/textlint"
MAX_SIZE=${MAX_SIZE:-102400}
ORIGINAL_DIR="$(pwd)"
FIX_MODE=false

# Parse options
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--fix" ]; then
    FIX_MODE=true
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

# Bootstrap
"$PLUGIN_ROOT/scripts/bootstrap.sh"

# Collect target files (resolve to absolute paths)
FILES=()
if [ $# -gt 0 ]; then
  for arg in "$@"; do
    # Resolve to absolute path
    if [[ "$arg" != /* ]]; then
      arg="$ORIGINAL_DIR/$arg"
    fi
    if [ -d "$arg" ]; then
      while IFS= read -r f; do
        FILES+=("$f")
      done < <(find "$arg" -type f \( -name '*.md' -o -name '*.txt' -o -name '*.rst' -o -name '*.re' \) 2>/dev/null)
    elif [ -f "$arg" ]; then
      FILES+=("$arg")
    fi
  done
else
  # Changed files (staged + unstaged + untracked)
  while IFS= read -r f; do
    [ -f "$f" ] && FILES+=("$(cd "$ORIGINAL_DIR" && realpath "$f")")
  done < <(cd "$ORIGINAL_DIR" && git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null || true)
  while IFS= read -r f; do
    [ -f "$f" ] && FILES+=("$(cd "$ORIGINAL_DIR" && realpath "$f")")
  done < <(cd "$ORIGINAL_DIR" && git diff --name-only --diff-filter=ACMR --cached 2>/dev/null || true)
  while IFS= read -r f; do
    [ -f "$f" ] && FILES+=("$(cd "$ORIGINAL_DIR" && realpath "$f")")
  done < <(cd "$ORIGINAL_DIR" && git ls-files --others --exclude-standard 2>/dev/null || true)
  # Deduplicate
  if [ ${#FILES[@]} -gt 0 ]; then
    IFS=$'\n' FILES=($(printf '%s\n' "${FILES[@]}" | sort -u))
    unset IFS
  fi
fi

# Filter: size limit
FILTERED=()
SKIPPED=()
for f in "${FILES[@]}"; do
  size=$(wc -c < "$f" 2>/dev/null || echo 0)
  size=$(echo "$size" | tr -d ' ')
  if [ "$size" -le "$MAX_SIZE" ]; then
    FILTERED+=("$f")
  else
    SKIPPED+=("$f")
  fi
done

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "Skipped (>${MAX_SIZE} bytes): ${SKIPPED[*]}" >&2
fi

if [ ${#FILTERED[@]} -eq 0 ]; then
  echo "No files to check." >&2
  echo '[]'
  exit 0
fi

# Determine textlint options
TEXTLINT_OPTS=("--format" "json")

# Use project .textlintrc if exists, otherwise use plugin config
HAS_CONFIG=false
for rc in ".textlintrc" ".textlintrc.json" ".textlintrc.yml" ".textlintrc.yaml" ".textlintrc.js"; do
  if [ -f "$ORIGINAL_DIR/$rc" ]; then
    HAS_CONFIG=true
    break
  fi
done

if [ "$HAS_CONFIG" = false ]; then
  TEXTLINT_OPTS+=("--config" "$PLUGIN_ROOT/.textlintrc.json")
fi

# Use project .textlintignore if exists, otherwise use plugin default
if [ -f "$ORIGINAL_DIR/.textlintignore" ]; then
  TEXTLINT_OPTS+=("--ignore-path" "$ORIGINAL_DIR/.textlintignore")
else
  TEXTLINT_OPTS+=("--ignore-path" "$PLUGIN_ROOT/.textlintignore")
fi

# Apply --fix if requested
if [ "$FIX_MODE" = true ]; then
  TEXTLINT_OPTS+=("--fix")
fi

# Run textlint from plugin root so node_modules resolution works
# Exit code 1 = lint errors found (not a script failure)
cd "$PLUGIN_ROOT"
"$TEXTLINT" "${TEXTLINT_OPTS[@]}" "${FILTERED[@]}" 2>/dev/null || true
