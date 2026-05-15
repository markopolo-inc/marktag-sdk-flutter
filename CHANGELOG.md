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
