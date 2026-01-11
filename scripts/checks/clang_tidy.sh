#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  exit 0
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR_DEFAULT="${TM_BUILD_DIR:-${HOME}/build/TextMate}"
CLANG_TIDY_BIN="${CLANG_TIDY:-clang-tidy}"
APPLE_CLANG="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
APPLE_CLANGXX="$(xcrun --sdk macosx --find clang++ 2>/dev/null || true)"
APPLE_SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

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

ORIGINAL_COMPDB="${COMPILATION_DATABASE_DIR}/compile_commands.json"
SANITIZED_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t clangtidy)"
SANITIZED_COMPDB="${SANITIZED_DIR}/compile_commands.json"

cleanup() {
  rm -rf "${SANITIZED_DIR}"
}
trap cleanup EXIT

export TM_TIDY_ORIG_COMPDB="${ORIGINAL_COMPDB}"
export TM_TIDY_SAN_COMPDB="${SANITIZED_COMPDB}"
export TM_TIDY_CLANG="${APPLE_CLANG}"
export TM_TIDY_CLANGXX="${APPLE_CLANGXX}"
export TM_TIDY_SDK="${APPLE_SDK_PATH}"
export TM_TIDY_BUILD_ROOT="${HOME}/build"

python3 <<'PY'
import json
import os
import shlex

orig_path = os.environ["TM_TIDY_ORIG_COMPDB"]
out_path = os.environ["TM_TIDY_SAN_COMPDB"]
clang_path = os.environ.get("TM_TIDY_CLANG", "")
clangxx_path = os.environ.get("TM_TIDY_CLANGXX", "")
sdk_path = os.environ.get("TM_TIDY_SDK", "")
build_root = os.environ.get("TM_TIDY_BUILD_ROOT", "")

with open(orig_path, 'r', encoding='utf-8') as fh:
  entries = json.load(fh)

sanitized = []
for entry in entries:
  args = entry.get('arguments')
  if not args:
    command = entry.get('command')
    if not command:
      continue
    args = shlex.split(command)

  filtered = []
  skip_next = False
  for idx, token in enumerate(args):
    if skip_next:
      skip_next = False
      continue
    if token == 'xcrun':
      continue
    if token == '--sdk':
      skip_next = True
      continue
    if token == 'macosx' and idx > 0 and args[idx - 1] == '--sdk':
      continue
    if token == '-include-pch':
      if idx + 1 < len(args):
        skip_next = True
      continue
    if token.startswith('-include-pch'):
      continue
    if token == '-Winvalid-pch':
      continue
    if token == '-I':
      if idx + 1 < len(args):
        include_dir = args[idx + 1]
  if build_root and include_dir.startswith(build_root):
          os.makedirs(include_dir, exist_ok=True)
        filtered.extend(['-I', include_dir])
        skip_next = True
        continue
    if token.startswith('-I'):
      include_dir = token[2:]
  if build_root and include_dir.startswith(build_root):
        os.makedirs(include_dir, exist_ok=True)
    filtered.append(token)

  if not filtered:
    continue

  compiler = os.path.basename(filtered[0]) if filtered else ''
  if 'clang++' in compiler and clangxx_path:
    filtered[0] = clangxx_path
  elif 'clang' in compiler and clang_path:
    filtered[0] = clang_path
  elif clang_path:
    filtered.insert(0, clang_path)

  if sdk_path and '-isysroot' not in filtered:
    filtered.insert(1, '-isysroot')
    filtered.insert(2, sdk_path)

  sanitized.append({
    'directory': entry.get('directory'),
    'file': entry.get('file'),
    'arguments': filtered,
  })

with open(out_path, 'w', encoding='utf-8') as fh:
  json.dump(sanitized, fh, indent=2)
PY

COMPILATION_DATABASE_DIR="${SANITIZED_DIR}"

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
