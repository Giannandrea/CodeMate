#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required but not found. Install it from https://brew.sh/." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Git is required but not found on PATH." >&2
  exit 1
fi

echo "Installing build dependencies via Brewfile…"
brew bundle --file="${REPO_ROOT}/Brewfile"

if command -v brew >/dev/null 2>&1; then
  LLVM_PREFIX="$(brew --prefix llvm 2>/dev/null || true)"
  if [[ -n "${LLVM_PREFIX}" ]]; then
    echo "Hint: add ${LLVM_PREFIX}/bin to your PATH to expose clang-format and clang-tidy."
  fi
fi

echo "Syncing submodules…"
git submodule update --init --recursive

echo "Generating Ninja build files…"
if [[ ! -x "${REPO_ROOT}/configure" ]]; then
  echo "configure script is missing or not executable." >&2
  exit 1
fi
(
  cd "${REPO_ROOT}"
  ./configure "$@"
)

BUILD_DIR_CANDIDATES=(
  "${REPO_ROOT}"
  "${TM_BUILD_DIR:-${HOME}/build/TextMate}"
)

for candidate in "${BUILD_DIR_CANDIDATES[@]}"; do
  if [[ -f "${candidate}/build.ninja" ]]; then
    echo "Generating compile_commands.json via ninja -t compdb…"
    (
      cd "${candidate}"
      ninja -t compdb > "${REPO_ROOT}/compile_commands.json"
    )
    break
  fi
done

echo "Installing pre-commit hooks…"
if command -v pre-commit >/dev/null 2>&1; then
  (cd "${REPO_ROOT}" && pre-commit install)
else
  echo "pre-commit not found on PATH. Install it (pip install pre-commit) to enable automatic linting." >&2
fi

echo "Bootstrap complete. Invoke 'ninja TextMate/run' from the repo root to build and launch."
