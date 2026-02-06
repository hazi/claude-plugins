---
name: jplint
description: "Japanese text linter using textlint with preset-japanese and JTF style rules. Use when asked to check Japanese writing quality, lint documents, review Japanese text style, or proofread Japanese prose."
argument-hint: "[file or directory paths...]"
allowed-tools: Bash, Read, Glob, Edit
version: 0.1.0
---

# Japanese Text Lint

Run `${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh $ARGUMENTS` via Bash to lint files.

- If no arguments given, the script automatically checks git-changed files
- Large files (>100KB) are automatically skipped
- If the project has `.textlintrc`, that config is used. Otherwise, the plugin's built-in config is applied

## False positive filtering

Before reporting, **read the source file** and exclude issues that are clearly false positives:

- **Quoted text / citations**: original text should not be modified.

When in doubt, **keep the original** and do not report it as an issue. Only report issues where the fix clearly improves readability of normal Japanese prose.

## Fixing

After reporting, fix issues in two steps:

### Step 1: textlint --fix (mechanical fixes)

Run `${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh --fix $ARGUMENTS` to apply textlint's auto-fix. This safely handles deterministic fixes without altering meaning.

### Step 2: Re-lint and handle remaining issues

Run `${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh $ARGUMENTS` again. For remaining issues:

- Apply fixes using the Edit tool with a brief explanation of each change.
- If a fix is ambiguous or could alter meaning, show the suggestion but do not apply it.
