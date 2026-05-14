## 0.2.0

- Upgrade to `device_info_plus` 13.x (Android `serialNumber` removed; use `androidInfo.id`).
- Use `package:http` for MarkTag and Cloudflare trace requests so the SDK runs on Flutter web.
- On web, skip the Cloudflare trace request (browsers block it with CORS) and send placeholder `x-cf-ip` / `x-cf-loc` / UAG fields; your ingest should still allow CORS on `POST https://<tag>/mark`.
- Set `event_source` to `web` when `kIsWeb` is true, otherwise `mobile`.
- Raise minimum constraints to Dart ^3.10 and Flutter >=3.38.0.

## 0.1.2+3

- Rename symbols

## 0.1.1+2

- Add support for collecting extra identifiers

## 0.1.0+1

- Initial version.