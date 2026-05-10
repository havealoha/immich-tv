# SKILLS.md

This file describes repo-specific working skills for future coding agents. These are not framework-level skills; they are the recurring task patterns that fit this codebase.

## 1. App Flow Skill

Use this when changing startup, saved-profile restoration, onboarding, or sign-out behavior.

- Start at `lib/src/features/app_flow/cubit/app_flow_cubit.dart` and `lib/src/app_shell.dart`.
- Keep stage transitions explicit and state-driven.
- Prefer extending `AppFlowState` and feature flows rather than introducing global mutable state.
- Re-test bootstrap, onboarding, and saved-profile entry paths with widget tests.

## 2. TV Focus And Remote Navigation Skill

Use this when changing sidebars, grids, dialogs, fullscreen controls, or any new actionable surface.

- Reuse `lib/src/shared/presentation/widgets/tv_focusable.dart` and related shared widgets.
- Support keyboard/remote activation via `enter`, `select`, and pointer tap.
- Ensure focus remains visible and scrollable containers keep focused items onscreen.
- Validate both pointer and remote-style navigation in widget tests when behavior changes.

## 3. Feature Cubit Skill

Use this when adding or changing view state in a screen-level feature.

- Keep async loading, pagination, and failure handling inside the feature Cubit.
- Use immutable state updates and surface user-safe error messages through state.
- Keep repository calls behind interfaces from `lib/src/core/repositories`.
- Mirror the existing pattern in `lib/src/features/library/cubit/library_cubit.dart` for staged loading and pagination.

## 4. Immich API Integration Skill

Use this when adding new server calls, media queries, or auth-related endpoints.

- Put API-specific code in a feature `data` implementation, not in widgets or Cubits.
- Build requests with the shared Dio factory and shared model types.
- Preserve `ServerConfig.apiEndpoint(...)` semantics so `/api` path handling stays correct.
- Add or update small unit tests when URL composition or normalization logic changes.

## 5. Persistence And Profile Skill

Use this when changing saved profiles, PIN flows, or session restoration.

- Keep profile lists in `SharedPreferences` and secrets in secure storage via `PlatformProfileStorage`.
- Preserve profile sorting by `lastUsedAt`.
- Treat secure-storage failures as user-facing app exceptions, not silent fallbacks.
- Avoid schema drift without migration handling if serialized profile models change.

## 6. Shared Presentation Skill

Use this when adding reusable visual primitives or responsive behavior.

- Put tokens and cross-feature building blocks under `lib/src/shared/presentation`.
- Prefer extending `AppColors`, spacing, radii, durations, breakpoints, and viewport helpers over new ad hoc constants.
- Keep large-screen readability and overscan-safe spacing in mind.
- If a widget is feature-specific, keep it in that feature instead of promoting it too early.

## 7. Test Harness Skill

Use this whenever a task changes user-visible behavior.

- Reuse the fake repository pattern in `test/widget_test.dart`.
- For widget tests, set a deterministic viewport before pumping the app.
- Cover the actual navigation path a remote user would take, not only direct method calls.
- Add narrow unit tests in `test/src/...` for pure logic and helpers.

## 8. Release Readiness Skill

Use this when working on platform packaging, launcher metadata, or store preparation.

- Check `docs/DEVELOPMENT_CHECKLIST.md` first so the work matches the active slice.
- Keep Android TV as the primary product target while avoiding regressions on desktop, web, and mobile.
- Verify that packaging changes do not leak into feature logic or shared runtime behavior.
- Update docs when platform capability assumptions or release steps change.
