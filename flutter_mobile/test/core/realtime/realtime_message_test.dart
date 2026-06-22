import 'dart:convert';

import 'package:erp_mobile/core/realtime/realtime_message.dart';
import 'package:test/test.dart';

void main() {
  group('RealtimeMessage.fromWire', () {
    test('decodes a kpi.update frame into the typed variant', () {
      final raw = jsonEncode({
        'kind': 'kpi.update',
        'id': 'revenue-mtd',
        'value': r'$84,210',
        'trend': 'up',
        'trendDelta': '+12.4 %',
      });

      final msg = RealtimeMessage.fromWire(raw);
      expect(msg, isA<RealtimeKpiUpdate>());
      final kpi = msg as RealtimeKpiUpdate;
      expect(kpi.id, 'revenue-mtd');
      expect(kpi.value, r'$84,210');
      expect(kpi.trend, 'up');
      expect(kpi.trendDelta, '+12.4 %');
    });

    test('decodes a kpi.update without trendDelta (optional field)', () {
      final raw = jsonEncode({
        'kind': 'kpi.update',
        'id': 'x',
        'value': '0',
        'trend': 'flat',
      });

      final msg = RealtimeMessage.fromWire(raw) as RealtimeKpiUpdate;
      expect(msg.trendDelta, isNull);
    });

    test('decodes a chart.update with parallel x/y arrays per series', () {
      final raw = jsonEncode({
        'kind': 'chart.update',
        'id': 'revenue-trend',
        'series': [
          {
            'id': 'revenue',
            'label': 'Revenue',
            'x': [1, 2, 3],
            'y': [62.0, 71.5, 84],
          },
        ],
      });

      final msg = RealtimeMessage.fromWire(raw) as RealtimeChartUpdate;
      expect(msg.id, 'revenue-trend');
      expect(msg.series, hasLength(1));
      final s = msg.series.first;
      expect(s.id, 'revenue');
      expect(s.label, 'Revenue');
      expect(s.x, [1.0, 2.0, 3.0]);
      expect(s.y, [62.0, 71.5, 84.0]);
    });

    test('pong frames decode to the singleton variant', () {
      final raw = jsonEncode({'kind': 'pong'});
      expect(RealtimeMessage.fromWire(raw), isA<RealtimePong>());
    });

    test('invalid JSON falls back to unknown (does not throw)', () {
      final msg = RealtimeMessage.fromWire('not json {{{') as RealtimeUnknown;
      expect(msg.raw, 'not json {{{');
      expect(msg.reason, contains('invalid JSON'));
    });

    test('non-object top-level falls back to unknown', () {
      final msg = RealtimeMessage.fromWire('[1, 2, 3]') as RealtimeUnknown;
      expect(msg.reason, contains('not an object'));
    });

    test('missing kind falls back to unknown', () {
      final raw = jsonEncode({'id': 'x', 'value': '0'});
      final msg = RealtimeMessage.fromWire(raw) as RealtimeUnknown;
      expect(msg.reason, contains('missing kind'));
    });

    test('unrecognised kind falls back to unknown (carries the kind)', () {
      final raw = jsonEncode({'kind': 'mystery.thing', 'id': 'x'});
      final msg = RealtimeMessage.fromWire(raw) as RealtimeUnknown;
      expect(msg.reason, contains('unknown kind: mystery.thing'));
    });

    test('type-cast failure inside a known kind falls back to unknown',
        () {
      // 'value' must be a String but we hand in an int → cast throws,
      // the use case absorbs it and tags the failure.
      final raw = jsonEncode({
        'kind': 'kpi.update',
        'id': 'x',
        'value': 123, // wrong type
        'trend': 'up',
      });
      final msg = RealtimeMessage.fromWire(raw) as RealtimeUnknown;
      expect(msg.reason, contains('decode error'));
    });
  });
}
