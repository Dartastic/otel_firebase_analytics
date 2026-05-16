# otel_firebase_analytics

OpenTelemetry instrumentation for
[`package:firebase_analytics`](https://pub.dev/packages/firebase_analytics),
built on the
[Dartastic OpenTelemetry SDK](https://pub.dev/packages/dartastic_opentelemetry).

Every Firebase Analytics call becomes an OTel span — so analytics
activity (add-to-cart, screen views, set user) appears alongside
your HTTP/Firestore/GraphQL spans in the same trace.

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:otel_firebase_analytics/otel_firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

await analytics.tracedLogEvent(
  name: 'add_to_cart',
  parameters: {'item_id': 'SKU-123', 'value': 9.99, 'quantity': 2},
);

await analytics.tracedLogScreenView(
  screenName: 'CartPage',
  screenClass: 'CartPage',
);

await analytics.tracedSetUserId(id: user.uid);
await analytics.tracedSetUserProperty(name: 'subscription', value: 'pro');
```

If you call analytics from inside a span (typical in a Flutter
checkout flow), the analytics span nests as a child:

```
HTTP POST /checkout            ←— OTel HTTP span
  ├─ firestore set orders/...  ←— Firestore span
  └─ analytics add_to_cart     ←— this package's span
```

## Span shape

- **Span name**: `analytics <event_name>` (e.g.
  `analytics add_to_cart`, `analytics screen_view`,
  `analytics set_user_id`)
- **Span kind**: `CLIENT`
- **Attributes**:
  - `analytics.system = firebase_analytics`
  - `analytics.event.name = <event name>`
  - `analytics.parameters.<key> = <value>` — flat fan-out of the
    parameters map. Values are coerced to `String` / `int` /
    `double` / `bool` (OTel attribute types); others are
    toString'd.
  - On `tracedLogScreenView`: `analytics.screen.name`,
    `analytics.screen.class`
  - On `tracedSetUserId`: `enduser.id` (OTel semconv)
  - On `tracedSetUserProperty`:
    `analytics.user_property.name`, `analytics.user_property.value`
- **Span status**: `Error` only if the underlying analytics call
  throws (typically it doesn't — Firebase Analytics is
  fire-and-forget on most platforms).

## Lower-level helper

```dart
await tracedAnalyticsCall<void>(
  eventName: 'add_to_cart',
  parameters: {'value': 9.99},
  invoke: () => myCustomAnalytics.send(...),
);
```

The extension methods are thin wrappers over this. Use it if
you're routing through a custom analytics backend or want to test
the span shape without a real `FirebaseAnalytics`.

## Self-recursion guard

```dart
await runWithoutFirebaseAnalyticsInstrumentationAsync(() async {
  await analytics.tracedLogEvent(name: 'quiet');
});
```

Inside the helper's zone the `traced*` methods become transparent
passthroughs.

## Caveats

- Firebase Analytics events have a hard limit of 25 parameters
  per event; this wrapper doesn't enforce that — the underlying
  Firebase call will if you exceed it. The span captures
  whatever you passed.
- The wrapper calls `OTel.tracerProvider().getTracer(...)` on each
  invocation — `OTel.initialize()` must have run first.
- Parameter values that aren't `String`/`int`/`double`/`bool` are
  toString'd into the attribute. OTel attributes don't accept
  nested maps/lists.

## License

Apache 2.0 — see `LICENSE`.
