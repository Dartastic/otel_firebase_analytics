// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_firebase_analytics/otel_firebase_analytics.dart';

class _MemorySpanExporter implements SpanExporter {
  final List<Span> spans = [];
  bool _shutdown = false;

  @override
  Future<void> export(List<Span> s) async {
    if (_shutdown) return;
    spans.addAll(s);
  }

  @override
  Future<void> forceFlush() async {}

  @override
  Future<void> shutdown() async {
    _shutdown = true;
  }
}

Map<String, Object> _attrs(Span span) =>
    {for (final a in span.attributes.toList()) a.key: a.value};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseAnalyticsSemantics', () {
    test('keys are the documented wire format', () {
      expect(FirebaseAnalyticsSemantics.system.key, 'analytics.system');
      expect(
        FirebaseAnalyticsSemantics.eventName.key,
        'analytics.event.name',
      );
      expect(
        FirebaseAnalyticsSemantics.screenName.key,
        'analytics.screen.name',
      );
      expect(
        FirebaseAnalyticsSemantics.screenClass.key,
        'analytics.screen.class',
      );
      expect(
        FirebaseAnalyticsSemantics.userPropertyName.key,
        'analytics.user_property.name',
      );
      expect(
        FirebaseAnalyticsSemantics.userPropertyValue.key,
        'analytics.user_property.value',
      );
      expect(analyticsParametersPrefix, 'analytics.parameters.');
    });
  });

  group('tracedAnalyticsCall', () {
    late _MemorySpanExporter exporter;

    setUp(() async {
      await OTel.reset();
      exporter = _MemorySpanExporter();
      await OTel.initialize(
        serviceName: 'firebase-analytics-otel-test',
        detectPlatformResources: false,
        spanProcessor: SimpleSpanProcessor(exporter),
      );
    });

    tearDown(() async {
      await OTel.shutdown();
      await OTel.reset();
    });

    test('emits CLIENT span with analytics.* + flat parameters', () async {
      await tracedAnalyticsCall<void>(
        eventName: 'add_to_cart',
        parameters: <String, Object?>{
          'item_id': 'SKU-123',
          'value': 9.99,
          'quantity': 2,
          'is_gift': true,
        },
        invoke: () async {},
      );

      final span = exporter.spans.single;
      expect(span.kind, equals(SpanKind.client));
      expect(span.name, equals('analytics add_to_cart'));
      final attrs = _attrs(span);
      expect(attrs['analytics.system'], equals('firebase_analytics'));
      expect(attrs['analytics.event.name'], equals('add_to_cart'));
      expect(attrs['analytics.parameters.item_id'], equals('SKU-123'));
      expect(attrs['analytics.parameters.value'], equals(9.99));
      expect(attrs['analytics.parameters.quantity'], equals(2));
      expect(attrs['analytics.parameters.is_gift'], equals(true));
    });

    test('extraAttrs land with no prefix', () async {
      await tracedAnalyticsCall<void>(
        eventName: 'set_user_id',
        extraAttrs: <String, Object?>{'enduser.id': 'u-42'},
        invoke: () async {},
      );

      final attrs = _attrs(exporter.spans.single);
      expect(attrs['enduser.id'], equals('u-42'));
      // extraAttrs should NOT receive the analytics.parameters. prefix
      expect(attrs.containsKey('analytics.parameters.enduser.id'), isFalse);
    });

    test('exception flips span to Error', () async {
      await expectLater(
        tracedAnalyticsCall<void>(
          eventName: 'boom',
          invoke: () async => throw StateError('nope'),
        ),
        throwsStateError,
      );

      final span = exporter.spans.single;
      expect(span.status, equals(SpanStatusCode.Error));
      expect(_attrs(span)['error.type'], equals('StateError'));
    });

    test('runWithoutFirebaseAnalyticsInstrumentationAsync bypasses spans',
        () async {
      await runWithoutFirebaseAnalyticsInstrumentationAsync(() async {
        await tracedAnalyticsCall<void>(
          eventName: 'login',
          invoke: () async {},
        );
      });
      expect(exporter.spans, isEmpty);
    });

    test('null parameter values are skipped', () async {
      await tracedAnalyticsCall<void>(
        eventName: 'foo',
        parameters: <String, Object?>{'present': 'yes', 'absent': null},
        invoke: () async {},
      );

      final attrs = _attrs(exporter.spans.single);
      expect(attrs['analytics.parameters.present'], equals('yes'));
      expect(attrs.containsKey('analytics.parameters.absent'), isFalse);
    });

    test('span inherits parent when called inside startActiveSpan', () async {
      await OTel.tracer().startActiveSpanAsync<void>(
        name: 'checkout',
        fn: (_) async {
          await tracedAnalyticsCall<void>(
            eventName: 'add_to_cart',
            invoke: () async {},
          );
        },
      );

      final parent = exporter.spans.firstWhere((s) => s.name == 'checkout');
      final child =
          exporter.spans.firstWhere((s) => s.name == 'analytics add_to_cart');
      expect(
        child.parentSpanContext?.spanId,
        equals(parent.spanContext.spanId),
      );
    });
  });
}
