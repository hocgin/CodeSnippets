#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}/Library/Developer/Xcode/UserData/CodeSnippets"

# 优先使用手动传入的源码目录，其次使用脚本所在目录的上一级（仓库根目录）。
SOURCE_DIR="${1:-}"

if [[ -z "${SOURCE_DIR}" && -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "stdin" ]]; then
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then
  echo "Usage: lnk.sh [SOURCE_DIR]" >&2
  echo "  SOURCE_DIR: 仓库根目录（包含 .codesnippet 文件）" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

shopt -s nullglob
SNIPPETS=("${SOURCE_DIR}"/*.codesnippet)
if [[ ${#SNIPPETS[@]} -eq 0 ]]; then
  echo "No .codesnippet files found in: ${SOURCE_DIR}" >&2
  exit 1
fi

linked=0
skipped=0

for snippet in "${SNIPPETS[@]}"; do
  name="$(basename "${snippet}")"
  target="${TARGET_DIR}/${name}"

  if [[ -L "${target}" ]]; then
    existing="$(readlink "${target}")"
    if [[ "${existing}" == "${snippet}" ]]; then
      skipped=$((skipped + 1))
      continue
    fi
    rm "${target}"
  elif [[ -e "${target}" ]]; then
    echo "Skip (file exists, not a symlink): ${name}" >&2
    skipped=$((skipped + 1))
    continue
  fi

  ln -s "${snippet}" "${target}"
  linked=$((linked + 1))
done

echo "Linked ${linked}, skipped ${skipped} -> ${TARGET_DIR}"
