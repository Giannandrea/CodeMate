# Modernization Roadmap

This document captures the long-term transition plan for evolving TextMate's codebase and developer experience to contemporary standards.

## Guiding Principles

- Maintain a releasable build at the end of each modernization milestone.
- Prefer automation, reproducibility, and verifiable quality gates over tribal knowledge.
- Leverage modern C++20/C++23 and Swift/Objective-C++ best practices while respecting the existing architecture.

## Milestones

### 1. Tooling & Environment Baseline *(in progress)*
- ✅ Provide a Homebrew bundle (`Brewfile`) to align local and CI dependency versions.
- ✅ Ship a repeatable bootstrap script (`scripts/bootstrap.sh`).
- ✅ Introduce unified formatting (`.clang-format`) and static analysis defaults (`.clang-tidy`).
- ✅ Migrate legacy CI to GitHub Actions with artifact caching and dependency bootstrapping.
- Publish containerized or declarative environments (Dev Containers / Nix / asdf).

### 2. Build System Evolution
- Author a CMake or Meson toolchain that replaces `bin/rave` outputs while still supporting Ninja.
- Model frameworks and apps as discrete targets with explicit dependencies.
- Centralize compiler flags, Apple SDK selection, and multi-architecture builds.

### 3. Language Modernization
- Adopt C++20 as the default standard and refactor core data structures to leverage modern facilities (concepts, ranges, smart pointers, `std::expected`).
- Ensure full ARC coverage, nullability annotations, and lightweight generics on Objective-C APIs.
- Introduce Swift modules for new UI components, bridged via XCFrameworks.

### 4. Architecture & Performance
- Isolate cross-cutting services (buffer, layout, bundle parsing) behind stable interfaces.
- Establish asynchronous workers for parsing and bundle execution with structured concurrency.
- Add performance and regression benchmarks; instrument the code with signposts and telemetry hooks.

### 5. Quality & Delivery
- Replace legacy test harnesses with Catch2/GoogleTest and XCTest, expanding coverage.
- Run sanitizers and fuzzers in nightly CI.
- Harden signing, sandboxing, and auto-update flows; integrate supply-chain scanning.

## Next Steps

1. [x] Enhance CI workflows to use the new bootstrap path, cache Homebrew artifacts, and run repository hooks.
2. [x] Add editorconfig and pre-commit hooks to enforce formatting and static analysis locally.
3. [x] Begin incremental refactors of shared data structures with modern C++ idioms (see `Frameworks/buffer/src/storage.{h,cc}`).
4. [x] Document ADRs for build-system decisions and module boundaries as they evolve.

Contributions aligned with this roadmap are welcome. Coordinate significant changes via issues or pull requests so the modernization remains cohesive and reviewable.
