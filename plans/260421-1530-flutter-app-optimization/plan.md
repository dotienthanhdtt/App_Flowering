---
title: "Flutter App Optimization — Performance, Memory, Structure, Network"
description: "Phased refactor addressing launch time, rebuild amplification, file-size violations, memory leaks, and network efficiency across the Flowering Flutter app."
status: pending
priority: P2
effort: ~22h
branch: main
tags: [optimization, performance, refactor, flutter]
created: 2026-04-21
---

# Flutter App Optimization Plan

## Context

Research by 4 parallel researchers covering performance, memory/leaks, code structure, and network efficiency.
See `research/researcher-01-performance.md` through `research/researcher-04-network-efficiency.md`.

## Guiding Principles
- **YAGNI**: no speculative abstractions (e.g. typed-preference bag, ResponseCacheService framework — only add where a real call site duplicates today).
- **KISS**: prefer the smallest change that captures the win (cache a sync token before designing a new storage API).
- **DRY**: only when a pattern repeats 2+ times in production code (not speculative future reuse).
- Ship in phases. Each phase independently merges & ships.

## Top 3 Highest-Value Optimizations (from research)
1. **Sync token cache in AuthInterceptor** (Researcher 04 N1) — saves 5-20ms per request on iOS, trivial diff.
2. **Scoped Obx in feed tabs + chat list** (Researcher 01 H2/H4) — eliminates list-wide rebuilds on typing/loading flips; directly felt as smoother scroll.
3. **`CachedNetworkImage` in scenario cards** (Researcher 01 H3) — cuts feed bandwidth and flicker; trivial 2-file edit.

## Phases (ordered by impact / risk)

| Phase | Title | Impact | Risk | Effort | Status |
|-------|-------|--------|------|--------|--------|
| 01 | Quick wins: token cache, image caching, retry safety | High | Low | 2h | pending |
| 02 | Rebuild optimizations: Obx scope, const, ListView | High | Low | 3h | pending |
| 03 | Split files >200 lines | Medium | Low | 5h | pending |
| 04 | Memory leak prevention: CancelToken, box lifecycle | Medium | Medium | 3h | pending |
| 05 | Startup time: deferred service init | Medium | Medium | 2h | pending |
| 06 | Network caching & debouncing | Medium | Medium | 3h | pending |
| 07 | Shared widgets + dead code removal | Low | Low | 2h | pending |
| 08 | Verification: flutter analyze, flutter test, manual smoke | — | — | 2h | pending |

## Key Dependencies
- Phases 01-03 have no cross dependencies — can run in any order.
- Phase 04 should run after Phase 03 (cleaner diff after splits).
- Phase 05 should run after Phase 04 (leaks fixed before changing init order).
- Phase 06 builds on Phase 01 (retry interceptor changes).
- Phase 08 always last.

## Out of Scope (explicit YAGNI)
- Adding ETag support (backend contract change).
- Rewriting TTS/STT stack — current architecture with providers is fine.
- Migrating from GetX to Riverpod/BLoC — architecturally irrelevant for these optimizations.
- Generalizing Hive preferences into a typed-bag pattern — only 3 keys today.

## Success Criteria
- `flutter analyze` passes with zero new warnings.
- `flutter test` passes.
- No file in `lib/` exceeds 200 lines (excluding l10n files, exemption documented).
- Manual smoke: login → onboarding chat → scenario feed → chat → settings returns no jank and no error banners.
- Cold-start visibly faster (subjective measurement against pre-change recording).
