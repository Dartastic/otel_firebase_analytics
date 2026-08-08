# otel_firebase_analytics example

```dart
// example/lib/main.dart

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:otel_firebase_analytics/otel_firebase_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Bring up OTel before the first analytics call.
  await OTel.initialize(
    serviceName: 'firebase-analytics-demo',
  );

  // 2. Firebase as usual.
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: CartPage());
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<void> _addToCart() async {
    final analytics = FirebaseAnalytics.instance;

    // ✨ Span: `analytics add_to_cart`
    //
    //    CLIENT span with analytics.system=firebase_analytics,
    //    analytics.event.name=add_to_cart, and a flat
    //    analytics.parameters.<key> attribute per parameter.
    await analytics.tracedLogEvent(
      name: 'add_to_cart',
      parameters: {'item_id': 'SKU-123', 'value': 9.99, 'quantity': 2},
    );
  }

  Future<void> _openCheckout() async {
    final analytics = FirebaseAnalytics.instance;

    // ✨ Span: `analytics screen_view`
    //
    //    Adds analytics.screen.name / analytics.screen.class.
    await analytics.tracedLogScreenView(
      screenName: 'CheckoutPage',
      screenClass: 'CheckoutPage',
    );
  }

  Future<void> _signIn(String uid) async {
    final analytics = FirebaseAnalytics.instance;

    // ✨ Span: `analytics set_user_id` — carries enduser.id.
    await analytics.tracedSetUserId(id: uid);

    // ✨ Span: `analytics set_user_property`
    //
    //    Carries analytics.user_property.name / .value.
    await analytics.tracedSetUserProperty(
      name: 'subscription',
      value: 'premium',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _addToCart,
          child: const Text('Add to cart'),
        ),
      ),
    );
  }
}
```

## Trace shape

Call the `traced*` methods from inside an active span (an HTTP
handler, a checkout flow) and the analytics span nests as a child:

```
HTTP POST /checkout
  ├─ firestore set orders/...
  └─ analytics add_to_cart        ←— this package's span
       analytics.system            = firebase_analytics
       analytics.event.name        = add_to_cart
       analytics.parameters.value  = 9.99
```

No real `FirebaseAnalytics` handy (tests, custom backends)? Use the
lower-level helper directly:

```dart
await tracedAnalyticsCall<void>(
  eventName: 'add_to_cart',
  parameters: {'value': 9.99},
  invoke: () async => myCustomAnalytics.send('add_to_cart'),
);
```
