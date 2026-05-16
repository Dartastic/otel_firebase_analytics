// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

/// Firebase Analytics attribute keys.
///
/// `analytics.*` isn't a stable OTel semconv namespace yet — this
/// enum holds the keys until upstream picks them up. Mirrors the
/// shape of `db.*` / `messaging.*` / `rpc.*`.
enum FirebaseAnalyticsSemantics implements OTelSemantic {
  /// `analytics.system` — constant `firebase_analytics`.
  system('analytics.system'),

  /// `analytics.event.name` — the event name passed to
  /// `FirebaseAnalytics.logEvent`.
  eventName('analytics.event.name'),

  /// `analytics.screen.name` — screen name on `logScreenView`.
  screenName('analytics.screen.name'),

  /// `analytics.screen.class` — screen class on `logScreenView`.
  screenClass('analytics.screen.class'),

  /// `analytics.user_property.name` — the property name on
  /// `setUserProperty`.
  userPropertyName('analytics.user_property.name');

  @override
  final String key;

  @override
  String toString() => key;

  const FirebaseAnalyticsSemantics(this.key);
}
