import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../models/assign_roles_request.dart';
import '../models/page_response.dart';
import '../models/user_dto.dart';
import '../models/user_requests.dart';

/// Surface over the Spring `UserController` at `/api/v1/users*`.
///
/// `/users/me` is open to any authenticated user — the rest are gated
/// by `USER_READ` / `USER_WRITE` permissions on the server. The auth
/// interceptor attaches the Bearer token automatically; callers don't
/// need to thread it through manually.
abstract class UsersRemoteDataSource {
  /// `GET /users/me` — the currently signed-in user. Used by My
  /// Profile, the AppBar avatar, and anywhere else that needs "who am
  /// I" without re-running login.
  Future<UserDto> me();

  /// `GET /users` — paginated + searchable.
  ///
  /// [page] is 1-indexed (matches the Spring default).
  /// [pageSize] caps at whatever the backend enforces (default 20).
  /// [search] is a free-text query — typically matches name + email.
  /// [sort] is a column expression like `"fullName,asc"` per Spring's
  /// `PageQuery` convention.
  Future<PageResponse<UserDto>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sort,
  });

  Future<UserDto> getUser(String id);
  Future<UserDto> createUser(CreateUserRequest body);
  Future<UserDto> updateUser(String id, UpdateUserRequest body);
  Future<void> deleteUser(String id);

  /// `POST /users/assign-roles` — bulk-assign one or more role codes
  /// to many users in a single call. Returns the updated [UserDto]s
  /// for every affected user (in backend-defined order).
  ///
  /// Use this instead of looping `updateUser` per-user: it's one HTTP
  /// round-trip, one DB transaction on the server, and supports the
  /// three mutation modes ([AssignRolesMode.add] /
  /// [AssignRolesMode.replace] / [AssignRolesMode.remove]).
  Future<List<UserDto>> assignRoles(AssignRolesRequest body);
}

/// `dio`-backed implementation. Resolves paths against
/// `dio.options.baseUrl` (e.g. `http://172.20.17.31:8080/api/v1`).
class DioUsersRemoteDataSource implements UsersRemoteDataSource {
  DioUsersRemoteDataSource({required Dio dio}) : _dio = dio;

  static const String basePath = '/users';
  static const String mePath = '/users/me';

  final Dio _dio;

  @override
  Future<UserDto> me() async {
    final res = await _dio.get<Map<String, dynamic>>(mePath);
    return ApiEnvelope.parse(res.data!, UserDto.fromJson);
  }

  @override
  Future<PageResponse<UserDto>> listUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sort,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      basePath,
      queryParameters: <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        // Only send `search` / `sort` when the caller actually provided
        // them — empty strings would show up as `?search=` which some
        // backends parse as a literal empty filter.
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
      },
    );
    return ApiEnvelope.parse(
      res.data!,
      (data) => PageResponse.fromJson<UserDto>(data, UserDto.fromJson),
    );
  }

  @override
  Future<UserDto> getUser(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('$basePath/$id');
    return ApiEnvelope.parse(res.data!, UserDto.fromJson);
  }

  @override
  Future<UserDto> createUser(CreateUserRequest body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      basePath,
      data: body.toJson(),
    );
    return ApiEnvelope.parse(res.data!, UserDto.fromJson);
  }

  @override
  Future<UserDto> updateUser(String id, UpdateUserRequest body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '$basePath/$id',
      data: body.toJson(),
    );
    return ApiEnvelope.parse(res.data!, UserDto.fromJson);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _dio.delete<dynamic>('$basePath/$id');
  }

  @override
  Future<List<UserDto>> assignRoles(AssignRolesRequest body) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$basePath/assign-roles',
      data: body.toJson(),
    );
    return ApiEnvelope.parseList(res.data!, UserDto.fromJson);
  }
}
