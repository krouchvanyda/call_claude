/// Slice 9.2.3 — multi-tenant / multi-environment API endpoint.
///
/// Pre-shipped environments (`prod`, `staging`, `local`) carry
/// `isBuiltIn=true` so the form refuses to delete them. Custom
/// tenant-specific endpoints can be added by admins and are deletable.
class ApiEnvironment {
  const ApiEnvironment({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String baseUrl;
  final bool isBuiltIn;

  ApiEnvironment copyWith({
    String? id,
    String? name,
    String? baseUrl,
    bool? isBuiltIn,
  }) =>
      ApiEnvironment(
        id: id ?? this.id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiEnvironment &&
          other.id == id &&
          other.name == name &&
          other.baseUrl == baseUrl &&
          other.isBuiltIn == isBuiltIn;

  @override
  int get hashCode => Object.hash(id, name, baseUrl, isBuiltIn);
}
