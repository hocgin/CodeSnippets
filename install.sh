#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}/Library/Developer/Xcode/UserData/CodeSnippets"
REPO_URL="https://github.com/hocgin/CodeSnippets.git"

# 优先使用手动传入的源码目录，其次使用脚本所在目录。
SOURCE_DIR="${1:-}"
TEMP_DIR=""

if [[ -z "${SOURCE_DIR}" && -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "stdin" ]]; then
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required when the source directory is not available locally." >&2
    exit 1
  fi

  # 通过临时克隆仓库来获取最新的 snippets。
  TEMP_DIR="$(mktemp -d)"
  trap '[[ -n "${TEMP_DIR}" ]] && rm -rf "${TEMP_DIR}"' EXIT
  git clone --depth 1 "${REPO_URL}" "${TEMP_DIR}" >/dev/null 2>&1
  SOURCE_DIR="${TEMP_DIR}"
fi

mkdir -p "${TARGET_DIR}"

# 只复制仓库里的 .codesnippet 文件，保持原文件名不变。
shopt -s nullglob
SNIPPETS=("${SOURCE_DIR}"/*.codesnippet)
if [[ ${#SNIPPETS[@]} -eq 0 ]]; then
  echo "No .codesnippet files found in: ${SOURCE_DIR}" >&2
  exit 1
fi

for snippet in "${SNIPPETS[@]}"; do
  cp -f "${snippet}" "${TARGET_DIR}/"
done

echo "Installed ${#SNIPPETS[@]} snippet(s) to: ${TARGET_DIR}"
