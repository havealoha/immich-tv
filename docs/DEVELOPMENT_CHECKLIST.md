# ImmichTV Development Checklist

This checklist is phase-based so we can move in deliberate slices while keeping Android TV as the product anchor and web, mobile, macOS, Linux, and Windows supported from the same Flutter codebase.

## Phase 0: Foundation and Product Alignment

- [x] Replace the Flutter starter app with an ImmichTV-branded shell.
- [x] Establish bootstrap, onboarding, and home-shell flow.
- [x] Add responsive layout behavior for TV-sized and smaller screens.
- [x] Add baseline widget coverage for first-launch flow.
- [x] Standardize on `flutter_bloc` for presentation state management.
- [x] Finalize folder conventions for `core`, `features`, `shared`, and `platform`.

## Phase 1: App Architecture and Session Flow

- [x] Introduce domain models for server config, authenticated session, user profile, album summary, and asset summary.
- [x] Implement repository interfaces for auth, server validation, and media browsing.
- [x] Add environment-safe configuration for API base URL handling and request headers.
- [x] Wire secure session persistence with platform-aware fallbacks.
- [x] Define global app flow BLoCs/Cubits for bootstrap, auth, and session restoration.
- [x] Add failure states and recovery paths for invalid server, auth failure, and expired session.

## Phase 2: Server Connection and Authentication

- [x] Normalize user-entered server URLs.
- [x] Validate server reachability and Immich compatibility before sign-in.
- [x] Implement real login against the Immich API.
- [x] Persist the authenticated session without storing the password.
- [x] Add sign-out and forced re-authentication flows.
- [x] Add platform-aware input UX:
  TV: remote-friendly focus targets and large keyboard prompts.
  Mobile/Web/Desktop: standard form interactions and keyboard shortcuts.

## Phase 3: Multi-Platform UX Foundation

- [x] Define adaptive breakpoints for TV, desktop, tablet, and phone layouts.
- [x] Build a shared design token layer for spacing, focus rings, typography, and color.
- [x] Add focus management patterns for TV remote navigation.
- [x] Add pointer, mouse, touch, and keyboard support where relevant.
- [ ] Confirm every critical flow works on Android TV, Android mobile, iOS, web, macOS, Windows, and Linux.
- [ ] Add platform capability notes for anything that must degrade gracefully.

## Phase 4: Library Browsing MVP

- [x] Fetch and display the main timeline feed.
- [x] Fetch and display albums.
- [x] Fetch and display favorites.
- [ ] Add asset grid virtualization and pagination.
- [ ] Add thumbnail loading and caching.
- [x] Build loading, empty, and error states for each tab.
- [x] Add high-level navigation between Timeline, Albums, Favorites, and Slideshow.

## Phase 5: Asset Viewer and Playback

- [ ] Build fullscreen image viewer.
- [ ] Build fullscreen video playback flow.
- [ ] Add next/previous asset navigation with remote, keyboard, and pointer support.
- [ ] Add slideshow playback controls, duration settings, and pause/resume.
- [ ] Add screen-safe overlays for metadata and transport controls.

## Phase 6: Performance and Reliability

- [ ] Measure initial load, scroll smoothness, and image memory behavior on TV hardware.
- [ ] Optimize thumbnail cache strategy and prefetching.
- [ ] Add retry behavior and offline-friendly handling for intermittent networks.
- [ ] Profile rebuild frequency in key BLoCs and widget trees.
- [ ] Add integration tests for boot, login, browse, and sign-out flows.

## Phase 7: Platform Packaging and Release Readiness

- [ ] Configure Android TV launcher metadata and store-ready packaging.
- [ ] Review Android mobile ergonomics for optional handheld support.
- [ ] Validate web deployment behavior for hosted TV browsers and desktop browsers.
- [ ] Verify desktop builds on macOS, Windows, and Linux.
- [ ] Add release versioning, app icons, screenshots, and distribution notes.
- [ ] Prepare a short QA checklist per platform before public testing.

## Immediate Next Slice

- [x] Add concrete auth and server-validation repositories.
- [x] Replace mock bootstrap and sign-in behavior with real Immich API calls.
- [x] Persist session state across launches.
- [x] Start the first TV-specific focus/navigation primitives.
