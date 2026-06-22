import 'dart:async';
import 'dart:developer' as developer;

import '../../../../core/error/failure.dart';
import '../../../../core/network/token_storage.dart';
import '../../../employees/data/datasources/employees_remote_data_source.dart';
import '../../../employees/data/models/employee_dto.dart';
import '../../../employees/data/models/employee_requests.dart';
import '../../entities/my_profile.dart';

/// Slice 9.1.4 — signed-in user's own profile.
///
/// Backed by the Spring `EmployeeController` at `/api/v1/employees`:
///   - `GET /employees/me`              → seeds the stream
///   - `PATCH /employees/{id}`          → [update]
///   - `POST /employees/me/avatar`      → [setAvatarPath]
///   - `DELETE /employees/me/avatar`    → [clearAvatar]
///
/// Lazy-loaded on the first [get] / [watch] call. Subsequent calls
/// read the in-memory snapshot; the broadcast stream re-emits after
/// every successful mutation so every observer (hero card, edit form,
/// avatar sheet) stays in sync without polling.
///
/// `avatarFilePath` is local-only and takes priority over [avatarUrl]
/// during the in-flight window between picking a photo and the
/// multipart upload completing. Once the server responds we replace
/// the local path with the resolved `avatarUrl` so subsequent renders
/// stream the canonical version.
class MyProfileRepository {
  MyProfileRepository({
    required EmployeesRemoteDataSource employees,
    required TokenStorage tokens,
  })  : _employees = employees,
        _tokens = tokens;

  final EmployeesRemoteDataSource _employees;

  /// Source of the access token attached to avatar requests. The repo
  /// reads it on every projection so a rotated token gets baked into
  /// the next snapshot without anyone having to invalidate manually.
  final TokenStorage _tokens;

  MyProfile? _state;
  Future<MyProfile>? _inflightLoad;
  final StreamController<MyProfile> _changes =
      StreamController<MyProfile>.broadcast();

  /// Returns the current snapshot — kicks off the network fetch on
  /// first call and caches the result. Concurrent callers during the
  /// first fetch share the same in-flight future so we don't hit the
  /// endpoint twice on cold start.
  Future<MyProfile> get() async {
    final cached = _state;
    if (cached != null) return cached;
    return _inflightLoad ??= _load().whenComplete(() => _inflightLoad = null);
  }

  /// Hot stream that emits the latest snapshot. First subscriber kicks
  /// off [get] so cold-start sees a value once the network comes back;
  /// every subsequent mutation re-emits via [_changes].
  Stream<MyProfile> watch() async* {
    final initial = await get();
    yield initial;
    yield* _changes.stream;
  }

  Future<MyProfile> _load() async {
    // Token read in parallel with the network call so we don't add
    // a second sequential hop. Avatar headers come from this token.
    final results = await Future.wait<dynamic>([
      _employees.me(),
      _tokens.read(),
    ]);
    final dto = results[0] as EmployeeDto?;
    final headers = _headersFrom(results[1]);
    final next = dto != null
        ? _projectFromDto(dto, previous: _state, avatarHeaders: headers)
        : _placeholderForMissingRecord();
    _state = next;
    if (!_changes.isClosed) _changes.add(next);
    return next;
  }

  /// `{Authorization: Bearer <token>}` when tokens are present.
  /// Returns `null` (no headers) when the user is logged out — in
  /// that case the avatar request would fail anyway, so emitting
  /// `null` headers + letting the 401 bubble up is fine.
  Map<String, String>? _headersFrom(Object? tokens) {
    if (tokens == null) return null;
    // `AuthTokens` is typed dynamic here to keep the data layer free
    // of an explicit import on `auth_tokens.dart` — the field name
    // is well-known across the codebase.
    try {
      final accessToken = (tokens as dynamic).accessToken as String?;
      if (accessToken == null || accessToken.isEmpty) return null;
      return <String, String>{'Authorization': 'Bearer $accessToken'};
    } catch (_) {
      return null;
    }
  }

  /// Persist a fully-validated edit via `PATCH /employees/{id}`. The
  /// backend gates this on `employee:write` (admin only) — non-admin
  /// callers will see a 403 here, which the page surfaces as a
  /// snackbar via [_errorMessage].
  Future<MyProfile> update(MyProfile next) async {
    final errors = <String, List<String>>{};
    if (next.name.trim().isEmpty) {
      errors.putIfAbsent('name', () => []).add('Required');
    }
    if (!_emailLooksValid(next.email)) {
      errors.putIfAbsent('email', () => []).add('Looks invalid');
    }
    if (next.phone.trim().isEmpty) {
      errors.putIfAbsent('phone', () => []).add('Required');
    }
    if (errors.isNotEmpty) {
      throw ValidationFailure(fieldErrors: errors);
    }
    // Use the numeric primary key, NOT the human-readable code.
    // Spring binds `@PathVariable Long id` and rejects the
    // `EMP-00004`-style code with `400 Malformed request`.
    final id = next.id;
    if (id.isEmpty) {
      // No employee record on the backend yet — can't PATCH a phantom.
      throw const Failure.network(
        message:
            'No employee record linked to this account. Ask an administrator to onboard you first.',
      );
    }
    final body = UpdateEmployeeRequest(
      fullName: next.name,
      email: next.email,
      phone: next.phone,
      address: next.address,
      dateOfBirth: next.birthdate,
      emergencyContactName: next.emergencyContactName,
      emergencyContactPhone: next.emergencyContactPhone,
    );
    // Diagnostic: log exactly what we're sending vs what comes back.
    // Removes guesswork when a field "doesn't update" — we can see
    // whether (a) we never sent the key, (b) we sent the wrong key
    // and the backend ignored it, or (c) the backend accepted it but
    // didn't echo it in the response (the projection then falls
    // back to the previous value, which looks like no-op to the UI).
    developer.log(
      '[MyProfile] PATCH /employees/$id body=${body.toJson()}',
      name: 'MyProfile',
    );
    final dto = await _employees.update(id, body);
    developer.log(
      '[MyProfile] PATCH response: '
      'emergencyContact=${dto.emergencyContactName} '
      'emergencyPhone=${dto.emergencyContactPhone} '
      'address=${dto.address} '
      'position=${dto.positionTitle}',
      name: 'MyProfile',
    );
    final projected = _projectFromDto(dto, previous: _state);
    _state = projected;
    if (!_changes.isClosed) _changes.add(projected);
    return projected;
  }

  /// Rotates the gradient tone shown when no photo is picked. Local-
  /// only — the backend doesn't store a tone preference; rotating it
  /// per session is good enough for the avatar palette UX.
  Future<MyProfile> setAvatarTone(int tone) async {
    final current = await get();
    final next = current.copyWith(avatarTone: tone % 4);
    _state = next;
    if (!_changes.isClosed) _changes.add(next);
    return next;
  }

  /// Picks a local file and uploads it via `POST /employees/me/avatar`.
  ///
  /// Two-phase update so the UI feels instant:
  ///   1. Emit immediately with `avatarFilePath` set to the local path
  ///      — the hero card switches off initials before the upload
  ///      starts, eliminating the perceived latency of a network call.
  ///   2. After the multipart upload resolves, replace with the
  ///      server's canonical `avatarUrl` and clear the local-file
  ///      override so subsequent loads stream the persisted version.
  ///
  /// On failure the local-file optimistic state is rolled back so the
  /// avatar doesn't show a stale picked image that didn't persist.
  Future<MyProfile> setAvatarPath(String path) async {
    final base = await get();
    final optimistic = base.copyWith(avatarFilePath: path);
    _state = optimistic;
    if (!_changes.isClosed) _changes.add(optimistic);

    try {
      // Refresh the avatar auth headers in case the auth interceptor
      // rotated the token between this and the previous load.
      final results = await Future.wait<dynamic>([
        _employees.uploadMyAvatar(path),
        _tokens.read(),
      ]);
      final dto = results[0] as EmployeeDto;
      final headers = _headersFrom(results[1]);
      final projected = _projectFromDto(
        dto,
        previous: _state,
        avatarHeaders: headers,
      )
          // Drop the local override now that we have the server URL —
          // future hot rebuilds and other observers should read the
          // canonical version, not the picker's temp file (which the
          // OS may garbage-collect after the upload completes).
          .copyWith(clearAvatarFilePath: true);
      _state = projected;
      if (!_changes.isClosed) _changes.add(projected);
      return projected;
    } catch (e) {
      // Roll back so the user doesn't think the upload stuck.
      _state = base;
      if (!_changes.isClosed) _changes.add(base);
      rethrow;
    }
  }

  /// "Remove photo" — DELETEs the server-side avatar and clears the
  /// local override. Backend returns the updated employee record so
  /// we can refresh from the response in one round-trip.
  Future<MyProfile> clearAvatar() async {
    final dto = await _employees.deleteMyAvatar();
    final next = _projectFromDto(dto, previous: _state).copyWith(
      clearAvatarFilePath: true,
      clearAvatarUrl: true,
    );
    _state = next;
    if (!_changes.isClosed) _changes.add(next);
    return next;
  }

  // ───────────────────────────────────────────────────────────────
  // Projection helpers
  // ───────────────────────────────────────────────────────────────

  /// Translates the Spring [EmployeeDto] into the page's view model.
  /// Fields the endpoint doesn't expose (role display, last-login,
  /// preferred avatar tone) are preserved from [previous] when
  /// available so partial reloads don't blank them.
  ///
  /// [avatarHeaders] should be passed by callers that just touched
  /// `TokenStorage`; omit to inherit whatever was on [previous] (used
  /// after a save that doesn't require re-resolving the token).
  MyProfile _projectFromDto(
    EmployeeDto dto, {
    MyProfile? previous,
    Map<String, String>? avatarHeaders,
  }) {
    return MyProfile(
      id: dto.id,
      name: dto.fullName,
      email: dto.email ?? previous?.email ?? '',
      phone: dto.phone ?? previous?.phone ?? '',
      employeeId: dto.code ?? dto.id,
      // `role` here is the HR position title (e.g. "Senior Developer").
      // RBAC roles (SUPER_ADMIN/STAFF/…) live on the User record and
      // surface on the My Roles & Permissions page — keep them split.
      // `position` is the HR job title (e.g. "Senior Developer"),
      // distinct from the RBAC role surfaced on the My Roles page.
      position: dto.positionTitle ?? previous?.position ?? '',
      department: dto.department ?? previous?.department ?? '',
      hiredAt: dto.hireDate ?? previous?.hiredAt ?? DateTime.utc(1970, 1, 1),
      birthdate:
          dto.dateOfBirth ?? previous?.birthdate ?? DateTime.utc(1970, 1, 1),
      address: dto.address ?? previous?.address ?? '',
      emergencyContactName:
          dto.emergencyContactName ?? previous?.emergencyContactName ?? '',
      emergencyContactPhone:
          dto.emergencyContactPhone ?? previous?.emergencyContactPhone ?? '',
      // `lastLoginAt` ships on `/employees/me` (confirmed); prefer it
      // over the previous snapshot. Device label isn't in the payload
      // yet — keep whatever was there (empty by default) until a
      // future `/users/me/sessions` endpoint surfaces it.
      lastLoginAt:
          dto.lastLoginAt ?? previous?.lastLoginAt ?? DateTime.utc(1970, 1, 1),
      lastLoginDevice: previous?.lastLoginDevice ?? '',
      avatarTone: previous?.avatarTone ?? 0,
      avatarUrl: dto.avatarUrl,
      avatarHeaders: avatarHeaders ?? previous?.avatarHeaders,
    );
  }

  /// 404 from `/employees/me` — user has a login but no HR record yet.
  /// We render an empty profile so the page still mounts; the Edit
  /// flow will surface a clear "no employee record" error when they
  /// try to save (no id to PATCH).
  MyProfile _placeholderForMissingRecord() {
    return MyProfile(
      id: '',
      name: '',
      email: '',
      phone: '',
      employeeId: '',
      position: '',
      department: '',
      hiredAt: DateTime.utc(1970, 1, 1),
      birthdate: DateTime.utc(1970, 1, 1),
      address: '',
      emergencyContactName: '',
      emergencyContactPhone: '',
      lastLoginAt: DateTime.utc(1970, 1, 1),
      lastLoginDevice: '',
      avatarTone: 0,
    );
  }
}

bool _emailLooksValid(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at == trimmed.length - 1) return false;
  if (trimmed.contains(' ')) return false;
  if (!trimmed.substring(at).contains('.')) return false;
  return true;
}

