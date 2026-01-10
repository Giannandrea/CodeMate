#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR_DEFAULT="${TM_BUILD_DIR:-${HOME}/build/TextMate}"
CLANG_TIDY_BIN="${CLANG_TIDY:-clang-tidy}"

if ! command -v "${CLANG_TIDY_BIN}" >/dev/null 2>&1; then
  echo "clang-tidy not found on PATH. Install LLVM via Homebrew (brew bundle) or set CLANG_TIDY." >&2
  exit 1
fi

if [[ -f "${REPO_ROOT}/compile_commands.json" ]]; then
  COMPILATION_DATABASE_DIR="${REPO_ROOT}"
elif [[ -f "${BUILD_DIR_DEFAULT}/compile_commands.json" ]]; then
  COMPILATION_DATABASE_DIR="${BUILD_DIR_DEFAULT}"
else
  echo "compile_commands.json not found. Run scripts/bootstrap.sh or generate a compilation database manually." >&2
  exit 0
fi

STATUS=0
for file in "$@"; do
  if [[ ! -f "${file}" ]]; then
    continue
  fi

  "${CLANG_TIDY_BIN}" \
    --quiet \
    --config-file="${REPO_ROOT}/.clang-tidy" \
    -p "${COMPILATION_DATABASE_DIR}" \
    --extra-arg=-std=c++20 \
    "${file}" || STATUS=$?
done

exit "${STATUS}"
