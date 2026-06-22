import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../models/role_dto.dart';
import '../models/role_requests.dart';

/// Surface over the Spring `RoleController` at `/api/v1/roles*`.
///
/// All routes are gated by `ROLE_READ` / `ROLE_WRITE` permissions on
/// the server — the auth interceptor attaches the Bearer token, so
/// callers don't need to thread it through manually. A 403 from the
/// server should surface as a typed `ForbiddenFailure` once a caller
/// wraps these calls in a repository with the standard
/// `failureFromDioException` translator.
abstract class RolesRemoteDataSource {
  Future<List<RoleDto>> listRoles();
  Future<RoleDto> getRole(String id);
  Future<RoleDto> createRole(CreateRoleRequest body);
  Future<RoleDto> updateRole(String id, UpdateRoleRequest body);
  Future<void> deleteRole(String id);

  /// Catalog of every permission scope the backend knows about — the
  /// role editor uses this to render the assignable chip list rather
  /// than hardcoding a Dart-side enum that can drift from the server.
  Future<List<PermissionDto>> listPermissions();
}

/// `dio`-backed implementation. Resolves paths against
/// `dio.options.baseUrl` (e.g. `http://172.20.17.31:8080/api/v1`), so
/// the relative paths below stay short.
class DioRolesRemoteDataSource implements RolesRemoteDataSource {
  DioRolesRemoteDataSource({required Dio dio}) : _dio = dio;

  // ── Endpoint paths (relative to baseUrl `…/api/v1`) ──────────
  static const String basePath = '/roles';
  static const String permissionsPath = '/roles/permissions';

  final Dio _dio;

  @override
  Future<List<RoleDto>> listRoles() async {
    final res = await _dio.get<Map<String, dynamic>>(basePath);
    return ApiEnvelope.parseList(res.data!, RoleDto.fromJson);
  }

  @override
  Future<RoleDto> getRole(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('$basePath/$id');
    return ApiEnvelope.parse(res.data!, RoleDto.fromJson);
  }

  @override
  Future<RoleDto> createRole(CreateRoleRequest body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      basePath,
      data: body.toJson(),
    );
    return ApiEnvelope.parse(res.data!, RoleDto.fromJson);
  }

  @override
  Future<RoleDto> updateRole(String id, UpdateRoleRequest body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '$basePath/$id',
      data: body.toJson(),
    );
    return ApiEnvelope.parse(res.data!, RoleDto.fromJson);
  }

  @override
  Future<void> deleteRole(String id) async {
    await _dio.delete<dynamic>('$basePath/$id');
  }

  @override
  Future<List<PermissionDto>> listPermissions() async {
    final res = await _dio.get<Map<String, dynamic>>(permissionsPath);
    return ApiEnvelope.parseList(res.data!, PermissionDto.fromJson);
  }
}
