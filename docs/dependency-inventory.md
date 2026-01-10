# Dependency Inventory (2026-01-10)

This document catalogs the key third-party components TextMate depends on today. It is intended to serve as a baseline before performing upgrades so we can track deltas and regression-test high-risk changes.

## Homebrew Formulae

| Component | Version | Notes |
| --- | --- | --- |
| boost | 1.90.0 | Latest stable per `brew info`; installs dependencies `icu4c@78`, `xz`, `zstd` |
| capnp | 1.3.0 | Requires CMake during build |
| google-sparsehash | 2.0.4 | Bottle only; no additional runtime deps |
| multimarkdown | 6.7.0 | Conflicts with `mtools`, `markdown`, `discount` due to binary name overlap |
| ninja | 1.13.2 | No extra dependencies |
| ragel | 6.10 | GPL-2.0-or-later license |
| llvm | 21.1.8 | Provides `clang-format`/`clang-tidy`; keg-only |

> _Command used_: `brew info --json=v2 boost capnp google-sparsehash multimarkdown ninja ragel llvm`

## Vendored Sources

| Component | Location | Reported Version | Notes |
| --- | --- | --- | --- |
| Onigmo | `vendor/Onigmo` | 5.13.5 (`PACKAGE_VERSION` in `config.h`) | Submodule @ `05da5931`; used for regex engine |
| kvdb | `vendor/kvdb/vendor` | (need upstream tag) | Submodule @ `13e30cf5`; leveldb/farmhash blend |

## Submodules

`git submodule status` (2026-01-10):

```
-a609c5cb Applications/SyntaxMate/resources/SyntaxMate.tmBundle
-80ee65a5 Applications/TextMate/icons
-fa2f59e3 PlugIns/dialog
-43df3148 PlugIns/dialog-1.x
-67c374d9 bin/CxxTest
-05da5931 vendor/Onigmo/vendor
-13e30cf5 vendor/kvdb/vendor
```

## Next

1. Confirm upstream release availability for each vendored component (Onigmo, kvdb, dialog, etc.) and capture target versions.
2. Create upgrade branches per component, run `./configure && ninja TextMate`, and exercise the relevant test suites.
3. Update CI to compile with `brew upgrade --formula` periodically so the inventory stays current.
