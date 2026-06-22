/// One-way signal the network layer fires when a refresh attempt fails and
/// the session must be torn down (router will react via its `AuthSession`
/// listener and bounce the user to `/login`).
///
/// Kept Flutter-free so the auth interceptor stays unit-testable. The DI
/// module bridges this to the concrete `AuthSession` implementation.
abstract class SessionSignal {
  Future<void> invalidate();
}
