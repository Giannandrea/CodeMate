#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FORMATTER="${CLANG_FORMAT:-clang-format}"

if ! command -v "${FORMATTER}" >/dev/null 2>&1; then
  CANDIDATES=(
    "${REPO_ROOT}/.venv/bin/clang-format"
  )
  if command -v brew >/dev/null 2>&1; then
    CANDIDATES+=("$(brew --prefix llvm 2>/dev/null)/bin/clang-format")
  fi
  for candidate in "${CANDIDATES[@]}"; do
    if [[ -x "${candidate}" ]]; then
      FORMATTER="${candidate}"
      break
    fi
  done
fi

if ! command -v "${FORMATTER}" >/dev/null 2>&1; then
  echo "Executable 'clang-format' not found. Install LLVM via Homebrew or set CLANG_FORMAT." >&2
  exit 1
fi

"${FORMATTER}" --style=file -i "$@"

