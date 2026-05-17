#!/bin/bash
# PostToolUse hook: Edit/Write した対象が .swift ファイルなら swift-format を実行する。
# 失敗してもツール実行自体はブロックしない（exit 0 を保つ）。

set -u

# Claude Code は JSON で hook 入力を渡す。tool_input.file_path を取り出す。
input="$(cat)"

file_path=$(printf '%s' "$input" | /usr/bin/python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# .swift 以外はスキップ
if [[ -z "${file_path}" ]] || [[ "${file_path}" != *.swift ]]; then
  exit 0
fi

# 存在しないファイルはスキップ
if [[ ! -f "${file_path}" ]]; then
  exit 0
fi

# プロジェクト直下の .swift-format 設定を使用
config_file="${CLAUDE_PROJECT_DIR:-$(pwd)}/.swift-format"

if /usr/bin/xcrun --find swift-format >/dev/null 2>&1; then
  if [[ -f "${config_file}" ]]; then
    /usr/bin/xcrun swift-format format --in-place --configuration "${config_file}" "${file_path}" 2>/dev/null || true
  else
    /usr/bin/xcrun swift-format format --in-place "${file_path}" 2>/dev/null || true
  fi
fi

exit 0
