import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a v4 UUID string.
///
/// Use this instead of `const Uuid().v4()` in table `clientDefault`s — drift's
/// codegen produces a generated file that lives in a different library from
/// the table source, so any private helper referenced there is inaccessible.
/// Public top-level function dodges that visibility trap.
String newUuid() => _uuid.v4();
