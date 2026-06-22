import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

/// Ensures the permissions a call needs are granted before the call is placed.
/// Returns `true` when the call may proceed.
///
/// **iOS-only** — on Android this returns `true` immediately so the existing
/// (working) Android call flow is completely unchanged.
///
/// Uses the **native** iOS permission prompt (`request()`) — the same
/// Allow / Don't Allow dialog iOS shows for notifications. No custom dialog:
///   * already granted → proceed
///   * not yet asked → the native system prompt appears
///   * denied → returns `false` and the caller simply doesn't open the call
///     (iOS won't re-show the native prompt once denied; the user re-enables
///     it from Settings)
Future<bool> ensureCallPermissions({bool needCamera = false}) async {
  if (!Platform.isIOS) return true; // Android flow unaffected.

  Future<bool> ensure(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted) return true;
    if (status.isDenied) status = await permission.request(); // native prompt
    return status.isGranted;
  }

  final micOk = await ensure(Permission.microphone);
  final camOk = needCamera ? await ensure(Permission.camera) : true;
  return micOk && camOk;
}
