import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:uuid/uuid.dart';

/// Maps a Stream call CID (e.g. `default:erp-call-1093`) to the id that is
/// handed to the cross-platform `flutter_callkit_incoming` plugin.
///
/// **Why this exists (iOS only).** Apple's CallKit requires every call id to
/// be a valid `UUID`. The plugin's native iOS layer force-unwraps
/// `UUID(uuidString: id)!`, so a raw CID like `default:erp-call-1093` makes
/// `endCall` crash with *"Unexpectedly found nil while unwrapping an
/// Optional value"*. We derive a **deterministic** UUIDv5 from the CID so the
/// id is identical across the two code paths that must agree:
///   * the show path (FCM background isolate → `showCallkitIncoming`)
///   * the end path (main isolate → `endCall` / dismiss)
/// Same CID always yields the same UUID, so show and end line up.
///
/// **Android is unchanged.** Android's notification flow keys show/dismiss off
/// the raw CID string and accepts arbitrary ids, so this returns the CID
/// verbatim there. It is a NO-OP on every platform except iOS (and on web).
/// The original CID is always preserved separately in `CallKitParams.extra`
/// (`call_cid`), which is what the event handler reads — so this mapping does
/// not affect accept/decline routing.
String callkitIdForCid(String cid) {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
    return cid;
  }
  final uuid = const Uuid().v5(Namespace.url.value, cid);
  // DIAGNOSTIC (iOS): surface the deterministic mapping so a 2-call repro
  // shows whether call #2 reused call #1's CID (⇒ same UUID ⇒ iOS refuses a
  // second reportNewIncomingCall) or got a distinct id. Remove once the
  // "second call shows no ring (minimized)" cause is confirmed.
  // ignore: avoid_print
  print('[CallkitId] cid=$cid → uuid=$uuid');
  return uuid;
}
