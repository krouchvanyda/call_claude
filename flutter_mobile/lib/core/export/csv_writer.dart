/// Pure-Dart CSV writer (Slice 3.3.3) — RFC 4180-style escaping.
///
/// **Quoting rules**:
/// - Fields containing `,`, `"`, `\r`, or `\n` are wrapped in double
///   quotes.
/// - Embedded `"` becomes `""` per RFC 4180.
/// - Plain ASCII / UTF-8 text passes through untouched.
///
/// **Line terminator**: `\r\n` for maximum spreadsheet compatibility
/// (Excel reads `\n` fine but emits `\r\n`; mirroring that avoids
/// "looks like one giant cell" surprises in older versions).
///
/// **Encoding**: caller decides — return value is a `String`. The
/// share/save layer encodes UTF-8 with BOM if Excel-on-Windows
/// compatibility matters; the writer stays codec-agnostic.
class CsvWriter {
  CsvWriter._();

  /// Encodes a single field value.
  static String escapeField(Object? value) {
    final text = value?.toString() ?? '';
    final needsQuoting = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    if (!needsQuoting) return text;
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  /// Joins one row's fields into a CSV line (no terminator).
  static String encodeRow(Iterable<Object?> fields) {
    return fields.map(escapeField).join(',');
  }

  /// Encodes header + rows into a full CSV document.
  static String encode({
    required List<String> header,
    required List<List<Object?>> rows,
  }) {
    final buffer = StringBuffer()
      ..write(encodeRow(header))
      ..write('\r\n');
    for (final row in rows) {
      buffer
        ..write(encodeRow(row))
        ..write('\r\n');
    }
    return buffer.toString();
  }
}
