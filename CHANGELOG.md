## 2.1.4

- Documentation: add a "Publishing a new version" guide to the README.
- CI: publish to pub.dev from `v*.*.*` tags via OIDC.

## 2.0.4

- Push-notification attribution payload now nests campaign data under `mtc` (`mtc_campaign`, `mtc_content`, `mtc_node`, `mtc_channel`) instead of `utm`, matching the web SDK's attribution structure.
- `msid` is recalculated after 30 minutes of inactivity, the marktag init call is now idempotent, and attribution is passed with all events after click.

## 2.0.3

- Add push notification open tracking via `PushNotificationTrackingService`.
- Widen Firebase dependency ranges for better compatibility with client apps.

## 2.0.2

- Remove `dependency_overrides` so pub publish validation passes.
- Align release metadata for pub.dev (CHANGELOG, version).

## 2.0.1

- Document `MarktagEvents` constants.
- Upgrade `very_good_analysis` to ^10.2.0 and apply related lint fixes.
- Add `@visibleForTesting` `ipService` getter on `PayloadService` for tests.
- Example app: use path dependency for local `marktag`, upgrade `flutter_lints` to ^6.0.0.

## 2.0.0

- Event names must be PascalCase (for example `AddToCart`, `PageView`). Snake_case and camelCase names throw `ArgumentError`.
- Add `MarktagEvents` constants for standard event names.
- Built-in helpers (`logLogin`, `logSearch`, `logSignup`, `logPageView`) use PascalCase event names aligned with the web SDK and server.

## 1.0.1

- `Marktag.init` now accepts an optional `serverId` for server-side (mobile) mode. When provided, the SDK sends `isServer: true` and `serverId` in the payload so the server can resolve the tenant by `serverSide.serverId` instead of relying on host-only routing.
- Server-side payloads no longer send `isClient: false` / `isServer: true` when no `serverId` is set; the keys are omitted entirely, letting the server fall through to its hostname lookup.

## 1.0.0

- Add Flutter web (client-side) support: SDK runs in browsers via `package:http` instead of `dart:io`.
- `Marktag.init` now accepts an optional `tagId`; when provided, the SDK uses client-side mode (`isClient: true`, `clientId` in payload, `?tagId=` in URL).
- Server-side mode (no `tagId`) preserves the original payload shape with `x-cf-ip` / `x-cf-loc` fields.
- Upgrade `device_info_plus` to `^13.1.0`; replace `Platform.isX` with `defaultTargetPlatform` for web compatibility.
- Raise minimum constraints to Dart `^3.10.0` and Flutter `>=3.38.0`.

## 0.1.2+3

- Rename symbols.

## 0.1.1+2

- Add support for collecting extra identifiers.

## 0.1.0+1

- Initial version.
