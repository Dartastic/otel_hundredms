// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_hundredms/otel_hundredms.dart';

/// Traces 100ms calls with OpenTelemetry.
///
/// `otel_hundredms` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each 100ms call in
/// [tracedHundredms]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'hundredms-example');

  // Wraps a 100ms REST API call in a CLIENT span.
  final hundredmsId = await tracedHundredms<String>(
    operation: 'rooms.create',
    region: 'us-east-1',
    invoke: () async {
      // Make the 100ms call here, then report what it returned.
      const id = 'hundredms_8f3a2c';
      return const HundredmsCallResult(
          value: id,
          result: HundredmsResult(
              roomId: 'room_8f3a2c',
              sessionId: 'session_8f3a2c',
              templateId: 'template_8f3a2c',
              peerCount: 3,
              peerMinutes: 1,
              rtmpEgressMinutes: 1,
              hlsEgressMinutes: 1,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedHundredms rooms.create returned $hundredmsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutHundredmsInstrumentationAsync.
  await runWithoutHundredmsInstrumentationAsync(
    () => tracedHundredms<String>(
      operation: 'rooms.create',
      region: 'us-east-1',
      invoke: () async {
        const id = 'hundredms_8f3a2c';
        return const HundredmsCallResult(
            value: id,
            result: HundredmsResult(
                roomId: 'room_8f3a2c',
                sessionId: 'session_8f3a2c',
                templateId: 'template_8f3a2c',
                peerCount: 3,
                peerMinutes: 1,
                rtmpEgressMinutes: 1,
                hlsEgressMinutes: 1,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
