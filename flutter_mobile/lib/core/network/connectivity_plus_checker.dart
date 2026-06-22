import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_checker.dart';

/// `connectivity_plus`-backed [ConnectivityChecker].
///
/// Bridges `Connectivity.onConnectivityChanged` (a `Stream<List<ConnectivityResult>>`)
/// down to a `Stream<bool>` via [isOnlineFromResults]. The mapping is exposed
/// as a static method so it can be unit-tested without spinning up the
/// platform plugin.
class ConnectivityPlusChecker implements ConnectivityChecker {
  ConnectivityPlusChecker(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async =>
      isOnlineFromResults(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(isOnlineFromResults).distinct();

  /// Returns `true` when *any* of the reported connectivity results is
  /// something other than [ConnectivityResult.none]. Encapsulates the
  /// platform-version awkwardness where a device reports both Wi-Fi and
  /// VPN at once, etc.
  static bool isOnlineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}
