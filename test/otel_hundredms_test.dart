// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_hundredms/otel_hundredms.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_hundredms-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('rooms.create records template + RTMP + HLS egress', () async {
    await tracedHundredms<String>(
      operation: 'rooms.create',
      region: 'in-mum',
      invoke: () async => const HundredmsCallResult(
        value: 'ok',
        result: HundredmsResult(
          roomId: 'r-1',
          sessionId: 's-1',
          templateId: 'tpl-broadcast',
          peerCount: 50,
          peerMinutes: 2000,
          rtmpEgressMinutes: 60,
          hlsEgressMinutes: 60,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('100ms rooms.create')!);
    expect(a['rpc.system'], 'hundredms');
    expect(a['hundredms.template.id'], 'tpl-broadcast');
    expect(a['hundredms.rtmp_egress_minutes'], 60);
    expect(a['hundredms.hls_egress_minutes'], 60);
    expect(a['cloud.region'], 'in-mum');
  });

  test('suppression skips spans', () async {
    await runWithoutHundredmsInstrumentationAsync(() async {
      await tracedHundredms<String>(
        operation: 'rooms.list',
        invoke: () async => const HundredmsCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('100ms '), isEmpty);
  });
}
