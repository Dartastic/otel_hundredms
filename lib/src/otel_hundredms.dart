// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_hundredms_suppression.dart';

const _tracerName = 'dartastic_otel_libs_hundredms';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class HundredmsResult {
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

class HundredmsCallResult<T> {
  const HundredmsCallResult({required this.value, this.result});
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
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.roomId != null) {
        extras.add(OTel.attributeString(
          'hundredms.room.id',
          r.result!.roomId!,
        ));
      }
      if (r.result!.sessionId != null) {
        extras.add(OTel.attributeString(
          'hundredms.session.id',
          r.result!.sessionId!,
        ));
      }
      if (r.result!.templateId != null) {
        extras.add(OTel.attributeString(
          'hundredms.template.id',
          r.result!.templateId!,
        ));
      }
      if (r.result!.peerCount != null) {
        extras.add(OTel.attributeInt(
          'hundredms.peer.count',
          r.result!.peerCount!,
        ));
      }
      if (r.result!.peerMinutes != null) {
        extras.add(OTel.attributeInt(
          'hundredms.peer_minutes',
          r.result!.peerMinutes!,
        ));
      }
      if (r.result!.rtmpEgressMinutes != null) {
        extras.add(OTel.attributeInt(
          'hundredms.rtmp_egress_minutes',
          r.result!.rtmpEgressMinutes!,
        ));
      }
      if (r.result!.hlsEgressMinutes != null) {
        extras.add(OTel.attributeInt(
          'hundredms.hls_egress_minutes',
          r.result!.hlsEgressMinutes!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
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
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
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
