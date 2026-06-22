import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../models/employee_dto.dart';
import '../models/employee_requests.dart';

/// Surface over the Spring `EmployeeController` at `/api/v1/employees*`.
///
/// `/employees/me` and `/employees/me/avatar` are open to any
/// authenticated user (no `@PreAuthorize`) — every other endpoint
/// requires `employee:read` / `employee:write`, which CUSTOMER + STAFF
/// don't have. The data source surfaces all of them anyway; the page
/// layer decides which ones to call based on context (My Profile uses
/// only `/me` + `/me/avatar`; an admin HR page would use the rest).
abstract class EmployeesRemoteDataSource {
  /// `GET /employees/me` — employee record for the currently signed-in
  /// user. Returns `null` when the user account isn't linked to an
  /// employee yet (Spring sends a 404 — we catch it so the profile
  /// page can fall back to a "no employee record" state).
  Future<EmployeeDto?> me();

  /// `PATCH /employees/{id}` — admin partial update. Requires
  /// `employee:write` on the server side; non-admin callers will get
  /// a 403 which the page surfaces as a snackbar.
  Future<EmployeeDto> update(String id, UpdateEmployeeRequest body);

  /// `POST /employees/me/avatar` (multipart) — upload + replace the
  /// signed-in user's avatar. Returns the updated [EmployeeDto] so
  /// the caller can read the new `avatarUrl` straight from the body.
  Future<EmployeeDto> uploadMyAvatar(String filePath);

  /// `DELETE /employees/me/avatar` — clear the signed-in user's
  /// avatar. Returns the updated [EmployeeDto] with `avatarUrl = null`.
  Future<EmployeeDto> deleteMyAvatar();
}

/// `dio`-backed implementation. Resolves paths against
/// `dio.options.baseUrl` (e.g. `http://172.20.17.31:8080/api/v1`).
class DioEmployeesRemoteDataSource implements EmployeesRemoteDataSource {
  DioEmployeesRemoteDataSource({required Dio dio}) : _dio = dio;

  static const String basePath = '/employees';
  static const String mePath = '/employees/me';
  static const String meAvatarPath = '/employees/me/avatar';

  final Dio _dio;

  @override
  Future<EmployeeDto?> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(mePath);
      return _parse(res.data!);
    } on DioException catch (e) {
      // 404 = user has no linked employee record yet. That's a
      // legitimate state (admin user created without HR onboarding),
      // not a failure — return null so the caller can render the
      // "no employee record" empty state instead of an error panel.
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<EmployeeDto> update(String id, UpdateEmployeeRequest body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '$basePath/$id',
      data: body.toJson(),
    );
    return _parse(res.data!);
  }

  @override
  Future<EmployeeDto> uploadMyAvatar(String filePath) async {
    // Spring expects `multipart/form-data` with a part named `file`
    // (matches the controller's `@RequestParam("file") MultipartFile`).
    // dio's `FormData.fromMap` infers the content type from the file
    // extension — JPEG / PNG / WebP all flow through unchanged.
    final form = FormData.fromMap(<String, dynamic>{
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      meAvatarPath,
      data: form,
    );
    return _parse(res.data!);
  }

  @override
  Future<EmployeeDto> deleteMyAvatar() async {
    final res = await _dio.delete<Map<String, dynamic>>(meAvatarPath);
    return _parse(res.data!);
  }

  /// Parse the envelope, then rewrite `avatarUrl` from a relative
  /// server path (`/uploads/avatars/…`) into a full URL so the UI's
  /// `NetworkImage` works without per-widget knowledge of the host.
  EmployeeDto _parse(Map<String, dynamic> body) {
    final dto = ApiEnvelope.parse(body, EmployeeDto.fromJson);
    final url = dto.avatarUrl;
    if (url == null || url.isEmpty) return dto;
    if (url.startsWith('http://') || url.startsWith('https://')) return dto;
    return dto.copyWith(avatarUrl: _resolveAgainstBase(url));
  }

  /// Joins a server-relative path (`/uploads/…`) with the Dio base
  /// URL's host root. Strips the `/api/v1` (or similar) prefix from
  /// the base because static uploads are served from the host root,
  /// not from under the API path.
  ///
  /// Examples (base = `http://172.20.17.31:8080/api/v1`):
  ///   - `/uploads/avatars/abc.jpg` → `http://172.20.17.31:8080/uploads/avatars/abc.jpg`
  ///   - `uploads/x.png`            → `http://172.20.17.31:8080/uploads/x.png`
  ///
  /// Built by string concat instead of `Uri.replace` — passing empty
  /// strings to `replace(query: '', fragment: '')` renders them as
  /// `?` and `#` separators (`?#`), producing `http://host?#/path`,
  /// which is what was reaching `NetworkImage` and 401-ing.
  String _resolveAgainstBase(String relative) {
    final base = Uri.parse(_dio.options.baseUrl);
    final port = base.hasPort ? ':${base.port}' : '';
    final host = '${base.scheme}://${base.host}$port';
    final path = relative.startsWith('/') ? relative : '/$relative';
    return '$host$path';
  }
}
