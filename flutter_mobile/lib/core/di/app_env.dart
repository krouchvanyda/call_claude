import '../config/environments.dart';

/// Application-wide environment / build-time configuration.
///
/// Pure value object — no framework deps. Registered into the DI graph by
/// [`AppModule`](register_module.dart) so we can supply literal defaults
/// instead of asking injectable to resolve every primitive.
class AppEnv {
  const AppEnv({
    required this.apiBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.enableNetworkLogging,
    this.oauthClientId = Environments.oauthClientId,
    this.oauthRedirectUri = Environments.oauthRedirectUri,
    this.realtimeUrl = Environments.localRealtimeUrl,
    this.realtimeEnabled = false,
  });

  /// Default profile used when no explicit environment is selected.
  ///
  /// Points at the local Spring backend by default. Swap to
  /// [Environments.stagingApiBaseUrl] or [Environments.prodApiBaseUrl] for
  /// build flavors. The URL must already include the `/api/v1` path
  /// prefix because dio resolves relative request paths (e.g.
  /// `/auth/login`) against it.
  factory AppEnv.defaults() => const AppEnv(
        apiBaseUrl: Environments.localApiBaseUrl,
        connectTimeoutMs: Environments.defaultConnectTimeoutMs,
        receiveTimeoutMs: Environments.defaultReceiveTimeoutMs,
        enableNetworkLogging: true,
      );

  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final bool enableNetworkLogging;

  // ── OAuth (Slice 1.2.2 PKCE) ─────────────────────────────────
  /// Public client identifier registered with the auth server. Per
  /// PKCE, this is **not** a secret — the proof comes from the
  /// `code_verifier`, not from a client secret.
  final String oauthClientId;

  /// Where the auth server redirects after the user signs in. Resolved
  /// natively on the device via a custom URI scheme + deep-link
  /// receiver (separate slice). The verifier-side use case sends this
  /// URI back to the server during code exchange so the server can
  /// confirm the redirect target hasn't been swapped.
  final String oauthRedirectUri;

  // ── Realtime (Slice 2.2.4) ───────────────────────────────────
  /// WebSocket endpoint for the dashboard real-time stream. Defaults
  /// to a placeholder; overridden per environment (staging / prod).
  final String realtimeUrl;

  /// Master switch — when `false` the dashboard skips `connect()` so a
  /// placeholder [realtimeUrl] (e.g. `api.example.com`) doesn't burn
  /// DNS lookups and battery on every reconnect attempt.
  ///
  /// Defaults to `false`: real WebSocket traffic only kicks in once
  /// an env profile sets both [realtimeUrl] AND `realtimeEnabled: true`.
  /// The status pill in the AppBar will read `Offline` until then.
  final bool realtimeEnabled;
}
