# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.2-wip]

## [0.3.1] - 2026-10-16

### Changed

- README: standard header naming the instrumented library, its supported platforms and project links; pubspec description to match.

## [0.3.0] - 2026-10-11

### Changed

- Requires `dartastic_opentelemetry_api >=1.0.0-rc.4 <1.0.0-rc.5`.
- **Breaking:** depends on `dartastic_opentelemetry_api` only, no
  longer on the SDK. The application chooses and initializes the
  OpenTelemetry SDK. Parameters and fields typed with SDK classes
  now use the API types (`APITracer`, `APISpan`, `APILogger`, ...);
  SDK instances are still accepted wherever an API type is expected.

## [0.2.0] - 2026-08-09

### Changed

- `firebase_analytics` floor raised to `^12.0.0` (latest major;
  verified against both `12.0.0` and the current `12.4.x`).
- All attribute keys are now typed constants: `enduser.id` comes from
  the registry `Enduser` enum, `analytics.user_property.value` joined
  `FirebaseAnalyticsSemantics`, and the `analytics.parameters.` fan-out
  prefix is the exported `analyticsParametersPrefix` constant. No
  emitted keys changed.

- Semantic conventions updated to the current OTel registry: deprecated
  attribute keys are no longer emitted (`db.system` -> `db.system.name`,
  `db.operation` -> `db.operation.name`, `rpc.system` -> `rpc.system.name`,
  with `rpc.service` folded into a fully-qualified `rpc.method`).
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

### Added

- `example/example.md` — end-to-end walkthrough (init, traced calls,
  resulting trace shape).
- Extension methods on `FirebaseAnalytics`:
  - `tracedLogEvent` — emits a CLIENT span named
    `analytics <event>` with `analytics.system`,
    `analytics.event.name`, and a flat
    `analytics.parameters.<key>` for each entry in the supplied
    parameters map.
  - `tracedLogScreenView` — emits a span named
    `analytics screen_view` with `analytics.screen.name` /
    `analytics.screen.class` attributes.
  - `tracedSetUserId` — emits a span and attaches the supplied
    UID as `enduser.id` so downstream traces show the user
    identity that was just set.
  - `tracedSetUserProperty` — emits a span carrying
    `analytics.user_property.name` and `.value`.
- `tracedAnalyticsCall<R>({eventName, invoke, parameters,
  extraAttrs})` — the generic helper underneath the extension
  methods. Useful when you can't or don't want to use a real
  `FirebaseAnalytics` (testing, custom backends).
- `runWithoutFirebaseAnalyticsInstrumentation` /
  `runWithoutFirebaseAnalyticsInstrumentationAsync` — zone-scoped
  suppression helpers.
- `FirebaseAnalyticsSemantics` — typed attribute-key enum for the
  `analytics.*` keys.
- Tests cover the full span shape (system + event + flat
  parameters with type coercion), extraAttrs without prefix,
  null-value skipping, exception path, suppression scope, and
  parent-span inheritance.
