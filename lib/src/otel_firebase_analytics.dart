// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_analytics_semantics.dart';
import 'firebase_analytics_suppression.dart';

const _tracerName = 'otel_firebase_analytics';
const _analyticsSystem = 'firebase_analytics';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Converts a map into attribute objects. [keyPrefix] is prepended
/// to each entry's key — pass `analytics.parameters.` for raw
/// analytics-event parameters, or the empty string when the keys
/// are already fully qualified semconv keys.
List<Attribute<Object>> _mapToAttributes(
  Map<String, Object?>? params, {
  required String keyPrefix,
}) {
  if (params == null || params.isEmpty) return const [];
  final attrs = <Attribute<Object>>[];
  for (final entry in params.entries) {
    final v = entry.value;
    if (v == null) continue;
    final key = '$keyPrefix${entry.key}';
    if (v is String) {
      attrs.add(OTel.attributeString(key, v));
    } else if (v is int) {
      attrs.add(OTel.attributeInt(key, v));
    } else if (v is double) {
      attrs.add(OTel.attributeDouble(key, v));
    } else if (v is bool) {
      attrs.add(OTel.attributeBool(key, v));
    } else {
      attrs.add(OTel.attributeString(key, v.toString()));
    }
  }
  return attrs;
}

/// Generic helper. Opens a CLIENT span named `analytics <eventName>`
/// with `analytics.system=firebase_analytics`,
/// `analytics.event.name=<eventName>`, and a flat
/// `analytics.parameters.<k>=<v>` for each entry in [parameters].
/// Runs [invoke] and ends the span on completion. Suitable for
/// testing without a real [FirebaseAnalytics].
Future<R> tracedAnalyticsCall<R>({
  required String eventName,
  required Future<R> Function() invoke,
  Map<String, Object?>? parameters,
  Map<String, Object?>? extraAttrs,
}) async {
  if (firebaseAnalyticsInstrumentationSuppressed()) return invoke();
  final attrs = <Attribute<Object>>[
    OTel.attributeString(
      FirebaseAnalyticsSemantics.system.key,
      _analyticsSystem,
    ),
    OTel.attributeString(
      FirebaseAnalyticsSemantics.eventName.key,
      eventName,
    ),
    ..._mapToAttributes(parameters, keyPrefix: analyticsParametersPrefix),
    ..._mapToAttributes(extraAttrs, keyPrefix: ''),
  ];
  final span = _tracer().startSpan(
    'analytics $eventName',
    kind: SpanKind.client,
    attributes: OTel.attributesFromList(attrs),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
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

/// Traced wrappers around [FirebaseAnalytics].
extension OTelFirebaseAnalytics on FirebaseAnalytics {
  /// Traced `logEvent`. Each parameter becomes an
  /// `analytics.parameters.<key>` attribute on the span.
  Future<void> tracedLogEvent({
    required String name,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) {
    return tracedAnalyticsCall<void>(
      eventName: name,
      parameters: parameters,
      invoke: () => logEvent(
        name: name,
        parameters: parameters,
        callOptions: callOptions,
      ),
    );
  }

  /// Traced `logScreenView`. Sets `analytics.screen.name` /
  /// `analytics.screen.class` attributes.
  Future<void> tracedLogScreenView({
    String? screenName,
    String? screenClass,
    Map<String, Object>? parameters,
    AnalyticsCallOptions? callOptions,
  }) {
    return tracedAnalyticsCall<void>(
      eventName: 'screen_view',
      parameters: parameters,
      extraAttrs: <String, Object?>{
        if (screenName != null)
          FirebaseAnalyticsSemantics.screenName.key: screenName,
        if (screenClass != null)
          FirebaseAnalyticsSemantics.screenClass.key: screenClass,
      },
      invoke: () => logScreenView(
        screenName: screenName,
        screenClass: screenClass,
        parameters: parameters,
        callOptions: callOptions,
      ),
    );
  }

  /// Traced `setUserId`. When [id] is non-null, attaches it as
  /// `enduser.id` on the span.
  Future<void> tracedSetUserId({
    String? id,
    AnalyticsCallOptions? callOptions,
  }) {
    return tracedAnalyticsCall<void>(
      eventName: 'set_user_id',
      extraAttrs: <String, Object?>{
        if (id != null) Enduser.enduserId.key: id,
      },
      invoke: () => setUserId(id: id, callOptions: callOptions),
    );
  }

  /// Traced `setUserProperty`.
  Future<void> tracedSetUserProperty({
    required String name,
    required String? value,
    AnalyticsCallOptions? callOptions,
  }) {
    return tracedAnalyticsCall<void>(
      eventName: 'set_user_property',
      extraAttrs: <String, Object?>{
        FirebaseAnalyticsSemantics.userPropertyName.key: name,
        if (value != null)
          FirebaseAnalyticsSemantics.userPropertyValue.key: value,
      },
      invoke: () => setUserProperty(
        name: name,
        value: value,
        callOptions: callOptions,
      ),
    );
  }
}
