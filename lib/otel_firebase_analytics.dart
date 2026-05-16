// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

/// OpenTelemetry instrumentation for `package:firebase_analytics`.
///
/// Each `logEvent` / `logScreenView` / `setUserId` /
/// `setUserProperty` call emits a CLIENT span with
/// `analytics.system=firebase_analytics` so analytics activity
/// appears alongside everything else in your traces.
library;

export 'src/firebase_analytics_semantics.dart';
export 'src/firebase_analytics_suppression.dart';
export 'src/otel_firebase_analytics.dart';
