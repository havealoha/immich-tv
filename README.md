# ImmichTV Project Document

## 1. Project Overview

**Project name:** ImmichTV
**Project type:** TV-first Immich client application
**Target platforms:** Android TV first, with optional future support for Apple TV, Fire TV, Google TV, and web-based TV browsers.
**Primary purpose:** Allow users to connect their self-hosted Immich server, authenticate, and browse their photos, videos, albums, and timeline in a TV-optimized interface.

ImmichTV is not a replacement for Immich server. It is a read-first client application that consumes the Immich REST API and displays the authenticated user’s photo library on a large screen. The experience should feel similar to the Immich web/mobile gallery but adapted for remote-control navigation, large thumbnails, slideshow viewing, and living-room usage.

---

## 2. Product Goals

### Main goals

1. Let users connect to their own Immich server by entering a server URL.
2. Validate the server before asking for credentials.
3. Authenticate using Immich email and password.
4. Store the authenticated session securely on the TV device.
5. Load and display the user’s media library.
6. Provide TV-friendly tabs for:
   - Photo Stream / Timeline
   - Albums
   - Favorites
   - Archive, optional
   - Videos, optional

7. Open individual assets in a fullscreen viewer.
8. Support remote-control navigation.
9. Support slideshow mode.
10. Handle large libraries efficiently with pagination, lazy loading, thumbnail caching, and virtualization.

### Non-goals for MVP

These should not be part of the first version unless required later:

1. Uploading photos or videos from TV.
2. Editing metadata.
3. Deleting assets.
4. Creating or modifying albums.
5. Face recognition management.
6. Admin settings.
7. Backup features.
8. Background sync from the TV device.

The first version should be read-only to reduce risk and simplify API permissions.

---

## 3. Target Users

### Primary users

People already running an Immich server who want to view their photo library on a TV.

### Use cases

1. Family photo browsing from the couch.
2. Viewing wedding, travel, family, or event albums on a large screen.
3. Running a continuous photo slideshow.
4. Turning a TV into a private photo frame.
5. Viewing shared Immich libraries from a self-hosted server.

---

## 4. Recommended Tech Stack

### Option A: Flutter for Android TV / Google TV

This is the recommended approach if the goal is to reuse your Flutter experience.

**Frontend:** Flutter
**State management:** GetX, BLoC, Riverpod, or plain ChangeNotifier depending on preference
**HTTP client:** Dio
**Secure storage:** flutter_secure_storage or platform channel-backed encrypted storage
**Image caching:** cached_network_image or custom Dio file cache
**Video playback:** video_player or better_player if video support is included
**Navigation:** go_router or GetX routing
**Target build:** Android TV APK / AAB

Advantages:

- Fast development if the team already knows Flutter.
- Good UI control for TV-style layouts.
- Can later support mobile/tablet if needed.
- Easier to create custom slideshow and gallery UI.

Risks:

- Flutter TV remote focus handling requires careful implementation.
- Some packages are mobile-first and may need TV testing.
- Image-heavy grids require performance optimization.

### Option B: Native Android TV with Kotlin

**Frontend:** Kotlin
**UI:** Jetpack Compose for TV or Leanback
**HTTP:** Retrofit + OkHttp
**Image loading:** Coil
**Storage:** EncryptedSharedPreferences / DataStore
**Video playback:** ExoPlayer / Media3

Advantages:

- Best native Android TV focus behavior.
- Strong media playback support.
- Better platform conventions for TV.

Risks:

- More native Android work.
- Harder to reuse Flutter knowledge.

### Recommended MVP stack

Use **Flutter for Android TV** for the first version, unless the app is expected to become a polished commercial TV app immediately. If the main goal is rapid development and learning, Flutter is a strong fit.

---

## 5. Official Immich References

Use the official documentation as the source of truth because Immich changes frequently.

### Main links

- Immich website: [https://immich.app/](https://immich.app/)
- Immich documentation: [https://docs.immich.app/](https://docs.immich.app/)
- Immich API documentation: [https://api.immich.app/](https://api.immich.app/)
- API documentation page: [https://docs.immich.app/api/](https://docs.immich.app/api/)
- Immich GitHub repository: [https://github.com/immich-app/immich](https://github.com/immich-app/immich)
- OpenAPI specification file: [https://github.com/immich-app/immich/blob/main/open-api/immich-openapi-specs.json](https://github.com/immich-app/immich/blob/main/open-api/immich-openapi-specs.json)

### Important note

Immich uses OpenAPI to generate API documentation and client SDKs. Always verify endpoint names, payload fields, and response models against the current API documentation before final implementation.

---

## 6. High-Level App Flow

### First launch flow

1. Show welcome screen.
2. User enters Immich server URL.
3. Normalize URL.
4. Validate server by calling public server configuration or status endpoint.
5. If server is valid, show login screen.
6. User enters email and password.
7. App calls login endpoint.
8. App receives session token / authentication response.
9. Store token and server URL securely.
10. Navigate to home screen.
11. Load initial gallery data.

### Returning user flow

1. App starts.
2. Read saved server URL and auth token.
3. Validate token if possible.
4. If valid, navigate to home.
5. If invalid, clear session and show login.

---

## 7. Authentication Design

### Primary auth method for MVP

Use Immich email/password login.

Expected endpoint:

```http
POST /auth/login
```

Expected request body:

```json
{
  "email": "user@example.com",
  "password": "user-password"
}
```

Expected result:

- Authenticated session information.
- Access token or session token depending on current Immich API response.
- User details.

### Token handling

Store:

```text
serverBaseUrl
accessToken/sessionToken
userId
userEmail
userName, if available
```

Use secure storage. Do not store passwords after login.

### Request header

After login, authenticated requests should include the correct auth header based on Immich API documentation. Common options may include bearer token or API-specific session handling. Confirm the exact current header from the API docs before implementation.

Example shape:

```http
Authorization: Bearer <token>
```

or API key style for API-key based flows:

```http
x-api-key: <api-key>
```

### Optional future auth methods

1. API key login.
2. OAuth / OIDC login.
3. PIN lock for local TV access.
4. QR-code login from web/mobile.

For a TV app, QR-code login would be a very strong future feature because typing email and password using a remote is painful.

---

## 8. Server URL Handling

Users may enter URLs in many forms:

```text
192.168.0.10:2283
http://192.168.0.10:2283
https://photos.example.com
https://photos.example.com/
https://photos.example.com/api
```

The app should normalize this carefully.

### Rules

1. Trim whitespace.
2. Add `http://` if no scheme is provided.
3. Remove trailing slash.
4. Detect whether the user entered the root server URL or the API base URL.
5. Store both if needed:
   - `serverRootUrl`
   - `apiBaseUrl`

### Example

```text
Input:  https://photos.example.com/
Root:   https://photos.example.com
API:    https://photos.example.com/api
```

### Server validation

Before login, call a public endpoint such as:

```http
GET /server/config
```

or another official public server endpoint from the current API docs.

Validation should check:

1. Server is reachable.
2. Response is JSON, not an HTML page.
3. Immich API endpoint exists.
4. Server version/config is readable if available.
5. Network error messages are user-friendly.

---

## 9. Core API Areas

### Authentication

Used for login, token validation, logout, OAuth, and session handling.

Important endpoints to review:

```http
POST /auth/login
GET or POST token validation endpoint, based on current docs
OAuth endpoints, optional
Session endpoints, optional
```

### Server

Used for checking whether the provided URL points to a valid Immich server.

Important endpoint:

```http
GET /server/config
```

### Assets

Assets represent uploaded images and videos.

Important capabilities:

1. Retrieve assets.
2. Retrieve asset details.
3. Retrieve thumbnails.
4. Retrieve original/full asset if needed.
5. Filter by type, favorite, archive, date, album, etc.

Important endpoints to review:

```http
GET /assets/{id}
GET /assets/{id}/thumbnail or equivalent thumbnail endpoint
POST /search/metadata or current metadata search endpoint
```

### Timeline

Timeline endpoints are useful for building a photo stream grouped by date.

Important capabilities:

1. Fetch time buckets.
2. Fetch assets for a specific time bucket.
3. Build year/month/day grouped browsing.

Important endpoints to review:

```http
GET /timeline/buckets or current time bucket endpoint
GET /timeline/bucket or current bucket assets endpoint
```

### Albums

Albums are collections of assets.

Important capabilities:

1. List albums.
2. Open album details.
3. Load album assets.
4. Display album thumbnail.

Important endpoint:

```http
GET /albums
GET /albums/{id}
```

### Search

Search can be added after MVP.

Possible features:

1. Search by text.
2. Search by metadata.
3. Search by date range.
4. Search by location.
5. Search by people/faces if exposed through the API.

---

## 10. App Architecture

### Suggested Flutter folder structure

```text
lib/
  main.dart
  app/
    app.dart
    routes.dart
    theme.dart
  core/
    constants/
    errors/
    network/
      api_client.dart
      auth_interceptor.dart
      server_url_normalizer.dart
    storage/
      secure_storage_service.dart
      cache_storage_service.dart
    utils/
  features/
    boot/
      presentation/
        splash_screen.dart
    server_setup/
      data/
      domain/
      presentation/
    auth/
      data/
        auth_remote_data_source.dart
        auth_repository_impl.dart
      domain/
        auth_repository.dart
        models/auth_session.dart
      presentation/
        login_screen.dart
        auth_controller.dart
    gallery/
      data/
        assets_remote_data_source.dart
        timeline_remote_data_source.dart
      domain/
        models/asset.dart
        models/timeline_bucket.dart
        repositories/gallery_repository.dart
      presentation/
        gallery_home_screen.dart
        photo_stream_tab.dart
        asset_grid.dart
    albums/
      data/
      domain/
      presentation/
        albums_tab.dart
        album_detail_screen.dart
    viewer/
      presentation/
        asset_viewer_screen.dart
        slideshow_screen.dart
    settings/
      presentation/
        settings_screen.dart
```

### Layers

Use a simple clean-ish architecture:

1. **Presentation:** Screens, widgets, controllers/blocs.
2. **Domain:** Models, repositories, business rules.
3. **Data:** API clients, DTOs, remote data sources, local cache.

Avoid over-engineering in MVP, but keep API/data code separated from UI.

---

## 11. Data Models

### AuthSession

```dart
class AuthSession {
  final String serverUrl;
  final String apiBaseUrl;
  final String accessToken;
  final String userId;
  final String email;
  final String? name;
}
```

### ImmichAsset

```dart
class ImmichAsset {
  final String id;
  final String type; // IMAGE or VIDEO
  final String? originalFileName;
  final DateTime? fileCreatedAt;
  final DateTime? localDateTime;
  final bool isFavorite;
  final bool isArchived;
  final String? thumbhash;
  final String? duration;
}
```

### ImmichAlbum

```dart
class ImmichAlbum {
  final String id;
  final String albumName;
  final String? description;
  final int assetCount;
  final String? albumThumbnailAssetId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### TimelineBucket

```dart
class TimelineBucket {
  final DateTime date;
  final int count;
}
```

The exact fields should be aligned with the generated OpenAPI models.

---

## 12. UI/UX Specification

## TV Design Principles

1. Large text.
2. Large thumbnail cards.
3. Clear focus state.
4. Minimal typing.
5. Remote-first navigation.
6. Avoid hover-only UI.
7. Avoid tiny icons.
8. Avoid deep nested menus.
9. Use safe overscan padding.
10. Prioritize smooth scrolling.

### Main screens

## 12.1 Welcome Screen

Purpose: Introduce ImmichTV and ask for server URL.

Components:

- App logo/name.
- Server URL input.
- Connect button.
- Help text: “Enter your Immich server URL, for example [https://photos.example.com”](https://photos.example.com”).
- Recent server URL shortcut if previously used.

States:

- Idle.
- Connecting.
- Invalid URL.
- Server not reachable.
- Server found.

## 12.2 Login Screen

Purpose: Authenticate user.

Components:

- Server URL display.
- Email input.
- Password input.
- Login button.
- Change server button.

Optional:

- QR login placeholder for future.
- API key login option.

## 12.3 Home Screen

TV layout:

```text
Top: ImmichTV logo / current user / settings
Tabs: Photo Stream | Albums | Favorites | Videos | Settings
Content: Large horizontal or vertical grid
```

Recommended MVP tabs:

1. Photo Stream
2. Albums
3. Favorites
4. Settings

## 12.4 Photo Stream Tab

Purpose: Show all photos/videos grouped by date.

Features:

- Lazy-loaded grid.
- Date section headers.
- Remote navigation.
- Open asset on select.
- Long press or menu button for options.

MVP options:

- View fullscreen.
- Start slideshow from here.
- Show details.

## 12.5 Albums Tab

Purpose: Show album grid.

Album card should show:

- Album cover.
- Album name.
- Asset count.

Selecting an album opens album detail page.

## 12.6 Album Detail Screen

Purpose: Show assets inside selected album.

Components:

- Back button.
- Album title.
- Asset count.
- Slideshow button.
- Asset grid.

## 12.7 Fullscreen Asset Viewer

Purpose: Display one image or video fullscreen.

Remote controls:

- Left: previous asset.
- Right: next asset.
- OK: show/hide controls.
- Back: close viewer.
- Play/Pause: pause slideshow or video.
- Up/Down: optional metadata panel.

Overlay controls:

- Asset date.
- File name.
- Favorite icon, read-only in MVP.
- Play slideshow.

## 12.8 Slideshow Mode

Purpose: Automatically cycle through assets.

Settings:

- 5 seconds.
- 10 seconds.
- 30 seconds.
- Shuffle on/off.
- Show only album/current tab.
- Include/exclude videos.

MVP behavior:

- Images advance automatically.
- Videos may be skipped in MVP or played with timeout.
- Remote OK pauses/resumes.
- Back exits.

## 12.9 Settings Screen

Settings:

- Current server URL.
- Logged-in user.
- Logout.
- Clear cache.
- Slideshow interval.
- Thumbnail quality.
- App version.

---

## 13. Navigation and Focus Handling

TV remote navigation is a core requirement.

### Required controls

| Remote input             | Action                      |
| ------------------------ | --------------------------- |
| D-pad Up/Down/Left/Right | Move focus                  |
| OK/Select                | Open selected item          |
| Back                     | Go back / close overlay     |
| Play/Pause               | Slideshow or video control  |
| Menu                     | Open options menu, optional |

### Flutter implementation notes

Use:

- FocusNode
- FocusTraversalGroup
- Shortcuts
- Actions
- RawKeyboardListener or KeyboardListener

Every clickable card must have a visible focused state.

Example focus styling:

- Scale selected card to 1.05.
- Add bright border.
- Add subtle background overlay.
- Keep focused card fully visible by scrolling into view.

---

## 14. Networking Design

### ApiClient responsibilities

1. Store base API URL.
2. Attach auth headers.
3. Handle JSON parsing.
4. Handle timeouts.
5. Handle token/session expiration.
6. Convert errors into app-level failures.

### Recommended Dio setup

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ),
);
```

### Error mapping

| Error                         | User message                                                              |
| ----------------------------- | ------------------------------------------------------------------------- |
| SocketException               | Cannot reach server. Check URL and network.                               |
| 401                           | Session expired. Please log in again.                                     |
| 403                           | You do not have permission to access this item.                           |
| 404                           | Resource not found.                                                       |
| HTML response instead of JSON | This does not look like the Immich API URL. Check reverse proxy/API path. |
| Timeout                       | Server took too long to respond.                                          |

---

## 15. Image Loading and Caching

Large photo libraries can easily make the app slow. Caching is mandatory.

### Thumbnail strategy

1. Load thumbnails first.
2. Use low-size thumbnail for grid cards.
3. Load larger preview/full image only in fullscreen viewer.
4. Cache thumbnails on disk.
5. Limit memory cache.
6. Cancel requests for offscreen items.

### Cache keys

```text
thumbnail:<assetId>:<size>
preview:<assetId>
album-cover:<albumId>:<assetId>
```

### Cache invalidation

For MVP:

- Use time-based cache expiry.
- Clear cache manually from settings.

Future:

- Use updatedAt/checksum/etag if available.

---

## 16. Pagination and Performance

### Requirements

1. Do not load all assets at once.
2. Use timeline buckets or paginated search endpoints.
3. Use virtualized grids.
4. Preload nearby thumbnails only.
5. Avoid expensive rebuilds.
6. Avoid decoding huge full-resolution images in the grid.

### Recommended loading strategy

For Photo Stream:

1. Load time buckets.
2. Display date sections.
3. Load assets for visible buckets.
4. Cache loaded bucket data.
5. Fetch more as user scrolls.

For Albums:

1. Load album list.
2. Load cover thumbnails.
3. Load album assets only when user opens an album.

---

## 17. Video Support

Video support can be added in MVP only if needed.

### MVP recommendation

Show videos in the grid with a play icon. In fullscreen viewer:

- Either play video using the official asset/video endpoint.
- Or show “Video playback coming soon” if implementation is delayed.

### Technical considerations

1. Use streaming endpoint if Immich provides one.
2. Support remote play/pause.
3. Handle buffering.
4. Avoid downloading full video before playback.
5. Use ExoPlayer/Media3 under the hood on Android.

---

## 18. Security Requirements

1. Never store password after login.
2. Store token/session securely.
3. Allow logout to clear all session data.
4. Hide password input.
5. Use HTTPS where possible.
6. Warn users when using plain HTTP over public networks.
7. Do not send media or credentials to any third-party server.
8. Keep the app client-only; all data comes directly from the user’s Immich server.

---

## 19. Privacy Requirements

ImmichTV should be privacy-preserving.

1. No analytics in MVP unless explicitly added later.
2. No crash logs containing server URLs, tokens, emails, or file names.
3. No third-party media proxy.
4. No external image processing.
5. Keep cached thumbnails local to the TV device.
6. Provide Clear Cache and Logout options.

---

## 20. Reverse Proxy and Self-Hosted Server Considerations

Many Immich users run their server behind:

- Nginx Proxy Manager
- Cloudflare Tunnel
- Tailscale
- Caddy
- Traefik
- Local IP with port 2283

The app should handle these scenarios carefully.

### Common problems

1. User enters web root instead of API URL.
2. Reverse proxy returns HTML instead of JSON.
3. HTTPS certificate issue.
4. Cloudflare access/auth page blocks API calls.
5. Server URL works in browser but not in API client.
6. Local server only works on LAN.

### Recommended diagnostics screen

Show a connection test with:

- Server reachable: yes/no.
- API reachable: yes/no.
- Response type: JSON/HTML/other.
- HTTP status code.
- Final resolved API URL.

---

## 21. Development Milestones

## Phase 1: Foundation

Tasks:

1. Create Flutter Android TV project.
2. Add app theme.
3. Implement focusable TV button/card components.
4. Implement routing.
5. Implement server URL input screen.
6. Implement server URL normalizer.
7. Implement basic API client.
8. Add server validation call.

Deliverable:

- User can enter a server URL and the app can validate the Immich API.

## Phase 2: Authentication

Tasks:

1. Build login screen.
2. Implement login API call.
3. Store session securely.
4. Restore session on app boot.
5. Add logout.
6. Add session expiration handling.

Deliverable:

- User can log in and stay logged in.

## Phase 3: Gallery MVP

Tasks:

1. Load timeline buckets or paginated assets.
2. Display photo stream grid.
3. Load thumbnails.
4. Implement lazy loading.
5. Implement fullscreen image viewer.
6. Add previous/next navigation.

Deliverable:

- User can browse and open photos.

## Phase 4: Albums

Tasks:

1. Load album list.
2. Display album grid.
3. Open album details.
4. Load album assets.
5. Add album slideshow.

Deliverable:

- User can browse albums and view album photos.

## Phase 5: Slideshow and Polish

Tasks:

1. Add slideshow mode.
2. Add slideshow settings.
3. Add cache manager.
4. Add error states.
5. Add loading skeletons/placeholders.
6. Improve focus animations.
7. Test on Android TV device/emulator.

Deliverable:

- App feels usable as a TV photo viewer.

## Phase 6: Optional Advanced Features

Tasks:

1. Add video playback.
2. Add favorites tab.
3. Add archive tab.
4. Add search.
5. Add people/faces browsing if API supports it.
6. Add QR-code login.
7. Add multi-server profiles.
8. Add screensaver/photo-frame mode.

---

## 22. MVP Feature Checklist

### Must-have

- Server URL setup.
- Server validation.
- Email/password login.
- Secure session storage.
- Photo stream tab.
- Albums tab.
- Thumbnail grid.
- Fullscreen image viewer.
- Remote navigation.
- Logout.
- Error handling.

### Should-have

- Slideshow mode.
- Favorites tab.
- Thumbnail cache.
- Clear cache.
- Server diagnostics.
- Large-screen optimized UI.

### Could-have

- Video playback.
- Search.
- QR login.
- Multiple server profiles.
- Screensaver mode.
- Album shuffle.

---

## 23. API Client Generation Option

Because Immich uses OpenAPI, you can generate a Dart client instead of manually writing endpoint classes.

### Pros

1. Models match current API schema.
2. Less manual JSON parsing.
3. Easier to discover endpoints.
4. Better long-term maintainability if regenerated per Immich version.

### Cons

1. Generated clients can be verbose.
2. You may still need wrappers for clean app architecture.
3. API changes may require regeneration and adaptation.

### Recommended approach

For MVP, manually implement only the required endpoints:

- Server config/status
- Login
- Validate token/session
- Albums
- Timeline/assets
- Thumbnail/preview

Later, switch to generated OpenAPI client if the endpoint surface grows.

---

## 24. Example API Service Interfaces

### AuthRepository

```dart
abstract class AuthRepository {
  Future<AuthSession> login({
    required String serverUrl,
    required String email,
    required String password,
  });

  Future<bool> validateSession();

  Future<void> logout();
}
```

### GalleryRepository

```dart
abstract class GalleryRepository {
  Future<List<TimelineBucket>> getTimelineBuckets();

  Future<List<ImmichAsset>> getAssetsForBucket({
    required TimelineBucket bucket,
  });

  String getThumbnailUrl(String assetId);

  String getPreviewUrl(String assetId);
}
```

### AlbumRepository

```dart
abstract class AlbumRepository {
  Future<List<ImmichAlbum>> getAlbums();

  Future<List<ImmichAsset>> getAlbumAssets(String albumId);
}
```

---

## 25. Testing Plan

### Unit tests

1. Server URL normalizer.
2. API error mapping.
3. Auth repository.
4. Asset DTO parsing.
5. Album DTO parsing.
6. Cache key generation.

### Widget tests

1. Welcome screen validation.
2. Login form validation.
3. Focus state rendering.
4. Grid loading state.
5. Error state widgets.

### Integration tests

1. Connect to test Immich server.
2. Login.
3. Load albums.
4. Load timeline.
5. Open fullscreen viewer.
6. Logout.

### Manual TV tests

1. Android TV emulator.
2. Real Google TV/Android TV device.
3. Remote navigation.
4. Large library performance.
5. Slow network behavior.
6. Reverse proxy server.
7. LAN server.
8. HTTPS server.
9. HTTP server.

---

## 26. Risks and Mitigation

| Risk                             | Impact                         | Mitigation                                         |
| -------------------------------- | ------------------------------ | -------------------------------------------------- |
| Immich API changes               | App breaks after server update | Use official OpenAPI docs and isolate API code     |
| Large libraries load slowly      | Poor UX                        | Use pagination, buckets, lazy loading, cache       |
| TV remote focus issues           | App feels broken               | Build reusable focusable components early          |
| Reverse proxy misconfiguration   | Login/server validation fails  | Add diagnostics and clear error messages           |
| Video playback complexity        | MVP delay                      | Treat video as optional after image browsing works |
| Secure storage limitations on TV | Session issues                 | Test secure storage on actual Android TV hardware  |

---

## 27. Suggested First Build Scope

The first working build should include only:

1. Server URL screen.
2. Login screen.
3. Auth/session storage.
4. Home shell with tabs.
5. Photo Stream tab.
6. Albums tab.
7. Thumbnail grid.
8. Fullscreen image viewer.
9. Logout.

Do not start with upload, edit, admin, or advanced search. The most important technical problem is fast, stable media browsing on a TV.

---

## 28. Future Feature Ideas

1. QR login from Immich web/mobile.
2. Screensaver mode.
3. Photo frame mode with random albums.
4. “Memories from this day” tab.
5. Favorites-only slideshow.
6. Shared album support.
7. Partner sharing support.
8. People/faces tab.
9. Location/map browsing.
10. Voice search.
11. Multiple Immich server profiles.
12. Guest/kids mode.
13. PIN lock before opening private albums.
14. Offline cached album for travel/home display.

---

## 29. Recommended Development Order

1. Build a minimal API client in Dart.
2. Validate server URL with `/server/config`.
3. Implement login.
4. Store token/session.
5. Hardcode a test call to fetch albums.
6. Show album names in a simple list.
7. Add thumbnails.
8. Build TV-focused cards and grid.
9. Add timeline/photo stream.
10. Add fullscreen viewer.
11. Add slideshow.
12. Polish UX and error handling.

---

## 30. Definition of Done for MVP

The MVP is complete when:

1. A user can install the app on Android TV.
2. A user can connect to their Immich server.
3. A user can log in with email/password.
4. The app restores the session after restart.
5. The user can browse photo stream.
6. The user can browse albums.
7. The user can open photos fullscreen.
8. The user can navigate everything with a remote.
9. The user can log out.
10. The app handles invalid server URL, invalid login, expired session, and network failure gracefully.

---

## 31. Final Recommendation

Start with a **read-only Android TV Flutter app**. Keep the first version narrow: connection, login, gallery, albums, fullscreen viewer, and slideshow. Treat Immich’s official API documentation and OpenAPI spec as the source of truth. Keep the networking layer isolated so API changes can be fixed in one place without rewriting the UI.

The app’s value will come from a smooth TV experience, not from copying every Immich web feature. Focus on large thumbnails, fast loading, remote navigation, and slideshow behavior first.
