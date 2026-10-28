// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_hundredms_suppression.dart';

const _tracerName = 'dartastic_otel_libs_hundredms';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class HundredmsResult {
  /// Creates a result.
  const HundredmsResult({
    this.roomId,
    this.sessionId,
    this.templateId,
    this.peerCount,
    this.peerMinutes,
    this.rtmpEgressMinutes,
    this.hlsEgressMinutes,
    this.statusCode,
  });

  final String? roomId;
  final String? sessionId;

  /// 100ms templates define role permissions and quality settings —
  /// the cost dimension you want to slice by.
  final String? templateId;
  final int? peerCount;
  final int? peerMinutes;

  /// Egress minutes through RTMP (live broadcasting to Twitch/YouTube).
  final int? rtmpEgressMinutes;

  /// Egress minutes through HLS (recorded playback).
  final int? hlsEgressMinutes;
  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class HundredmsCallResult<T> {
  /// Creates a call result.
  const HundredmsCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final HundredmsResult? result;
}

/// Wraps a 100ms REST API call in a CLIENT span. [operation] is the
/// route like `rooms.create`, `sessions.list`, `recordings.start`,
/// `auth_tokens.app`, `egress.start`.
Future<T> tracedHundredms<T>({
  required String operation,
  required Future<HundredmsCallResult<T>> Function() invoke,
  String? region,
}) async {
  if (hundredmsInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'hundredms',
    'rpc.method': operation,
  };
  if (region != null) m['cloud.region'] = region;

  final span = _tracer().startSpan(
    '100ms $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.roomId != null) {
        extras.add(OTelAPI.attributeString(
          'hundredms.room.id',
          r.result!.roomId!,
        ));
      }
      if (r.result!.sessionId != null) {
        extras.add(OTelAPI.attributeString(
          'hundredms.session.id',
          r.result!.sessionId!,
        ));
      }
      if (r.result!.templateId != null) {
        extras.add(OTelAPI.attributeString(
          'hundredms.template.id',
          r.result!.templateId!,
        ));
      }
      if (r.result!.peerCount != null) {
        extras.add(OTelAPI.attributeInt(
          'hundredms.peer.count',
          r.result!.peerCount!,
        ));
      }
      if (r.result!.peerMinutes != null) {
        extras.add(OTelAPI.attributeInt(
          'hundredms.peer_minutes',
          r.result!.peerMinutes!,
        ));
      }
      if (r.result!.rtmpEgressMinutes != null) {
        extras.add(OTelAPI.attributeInt(
          'hundredms.rtmp_egress_minutes',
          r.result!.rtmpEgressMinutes!,
        ));
      }
      if (r.result!.hlsEgressMinutes != null) {
        extras.add(OTelAPI.attributeInt(
          'hundredms.hls_egress_minutes',
          r.result!.hlsEgressMinutes!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            '100ms status ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
