/// Mutation kind being replayed against the server.
///
/// Stored as the enum *name* in drift (`textEnum<SyncOpType>()`) so renames
/// here force a deliberate migration step rather than silently shifting
/// integer indices.
enum SyncOpType { create, update, delete }
