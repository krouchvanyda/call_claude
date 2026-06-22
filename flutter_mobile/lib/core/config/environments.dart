/// Centralized backend environment URLs.
///
/// Single source of truth for every backend API base URL used by the app.
/// Other modules (settings seed, dio bootstrap, WebSocket clients) should
/// import this file instead of hardcoding URLs inline — so swapping a host
/// or rolling a new region only takes one edit.
///
/// Mapping to the Spring backend:
///   - REST root is mounted at `/api/v1/*` (see `AuthController` etc.)
///   - WebSocket endpoints share the same host, scheme bumped to `ws(s)`.
///
/// Whenever you add a new environment, also register it in
/// `SettingsSeed.environments` so the in-app API Configuration page can
/// surface it as a switchable cluster.
class Environments {
  Environments._();

  // ── Production ────────────────────────────────────────────────
  static const String prodApiBaseUrl = 'http://172.26.17.118:8080/api/v1';
  static const String prodRealtimeUrl = 'ws://172.26.17.118:8080/realtime';

  // ── Staging ───────────────────────────────────────────────────
  static const String stagingApiBaseUrl = 'http://172.26.17.118:8080/api/v1';
  static const String stagingRealtimeUrl = 'ws://172.26.17.118:8080/realtime';

  // ── Local dev ─────────────────────────────────────────────────
  /// Points at the local Spring backend (`AuthController` at
  /// `/api/v1/auth/*`).
  ///
  /// Target-specific host:
  ///   - Physical phone on WiFi → dev machine's LAN IP (current value)
  ///   - Android emulator       → `10.0.2.2` (special alias for host)
  ///   - iOS simulator / web    → `localhost`
  ///
  /// If your laptop's LAN IP changes (DHCP lease rolled, switched
  /// networks), update this value and hot-restart the app.
  static const String localApiBaseUrl = 'http://172.26.17.118:8080/api/v1';
  static const String localRealtimeUrl = 'ws://172.26.17.118:8080/realtime';

  // ── Common defaults ───────────────────────────────────────────
  /// Network timeouts in milliseconds. Override per-env if a slow
  /// region needs a longer budget.
  static const int defaultConnectTimeoutMs = 15000;
  static const int defaultReceiveTimeoutMs = 20000;

  /// OAuth2 PKCE — public client id, NOT a secret. The proof comes from
  /// the `code_verifier`, never from a client secret.
  static const String oauthClientId = 'erp-mobile-dev';
  static const String oauthRedirectUri = 'erpmobile://oauth/callback';
}
