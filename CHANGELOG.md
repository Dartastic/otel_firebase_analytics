# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-beta.1-wip]

### Added

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
