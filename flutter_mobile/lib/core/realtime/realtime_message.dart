import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'realtime_message.freezed.dart';
part 'realtime_message.g.dart';

/// Server-pushed message envelope for the dashboard real-time stream
/// (Slice 2.2.4).
///
/// Sealed union — adding a new push kind is a one-line freezed factory
/// + a matching JSON discriminator. Intentionally NOT json_serializable:
/// the discriminator-keyed `fromJson` is hand-rolled because freezed's
/// auto-generated union deserialiser doesn't fit our wire format
/// (`{"kind": "kpi.update", "id": ..., ...}`) without ceremony.
///
/// **Pure data**: no Flutter, no dio, no fl_chart. Feature blocs fan
/// out incoming messages into their own state without depending on the
/// realtime infrastructure.
@freezed
sealed class RealtimeMessage with _$RealtimeMessage {
  /// Updated KPI tile values. The widget layer maps `(id, value, ...)`
  /// onto the dashboard layout via the slot's `id`.
  const factory RealtimeMessage.kpiUpdate({
    required String id,
    required String value,
    required String trend,
    String? trendDelta,
  }) = RealtimeKpiUpdate;

  /// Replacement series payload for a chart slot — the entire newest
  /// snapshot (no incremental deltas yet; that's a later slice).
  const factory RealtimeMessage.chartUpdate({
    required String id,
    required List<RealtimeChartSeriesPayload> series,
  }) = RealtimeChartUpdate;

  /// Heartbeat ack. The service swallows these — they only exist so
  /// the connection can prove it's alive without producing user-visible
  /// state churn.
  const factory RealtimeMessage.pong() = RealtimePong;

  /// Anything we couldn't decode — surfaced (not silently dropped) so
  /// the service can log / count it. Carries the raw payload for
  /// post-mortem.
  const factory RealtimeMessage.unknown({
    required String raw,
    String? reason,
  }) = RealtimeUnknown;

  // ── JSON ────────────────────────────────────────────────────────
  /// Decode a server frame. Never throws — unrecognised / malformed
  /// payloads come back as [RealtimeMessage.unknown] so the caller can
  /// log without a crash loop on a bad server build.
  static RealtimeMessage fromWire(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      return RealtimeMessage.unknown(raw: raw, reason: 'invalid JSON: $e');
    }
    if (decoded is! Map<String, dynamic>) {
      return RealtimeMessage.unknown(
        raw: raw,
        reason: 'top level is not an object',
      );
    }
    final kind = decoded['kind'];
    if (kind is! String) {
      return RealtimeMessage.unknown(raw: raw, reason: 'missing kind');
    }
    try {
      return switch (kind) {
        'kpi.update' => RealtimeMessage.kpiUpdate(
            id: decoded['id'] as String,
            value: decoded['value'] as String,
            trend: decoded['trend'] as String,
            trendDelta: decoded['trendDelta'] as String?,
          ),
        'chart.update' => RealtimeMessage.chartUpdate(
            id: decoded['id'] as String,
            series: [
              for (final s in decoded['series'] as List<dynamic>)
                RealtimeChartSeriesPayload.fromJson(
                  s as Map<String, dynamic>,
                ),
            ],
          ),
        'pong' => const RealtimeMessage.pong(),
        _ => RealtimeMessage.unknown(raw: raw, reason: 'unknown kind: $kind'),
      };
    } catch (e) {
      return RealtimeMessage.unknown(raw: raw, reason: 'decode error: $e');
    }
  }
}

/// One series in a [RealtimeChartUpdate] payload — kept structural
/// (parallel arrays for x / y) so 100-point updates stay compact on
/// the wire. JSON (de)serialization is delegated to json_serializable
/// via the standard freezed convention.
@freezed
class RealtimeChartSeriesPayload with _$RealtimeChartSeriesPayload {
  const factory RealtimeChartSeriesPayload({
    required String id,
    required String label,
    required List<double> x,
    required List<double> y,
  }) = _RealtimeChartSeriesPayload;

  factory RealtimeChartSeriesPayload.fromJson(Map<String, dynamic> json) =>
      _$RealtimeChartSeriesPayloadFromJson(json);
}
