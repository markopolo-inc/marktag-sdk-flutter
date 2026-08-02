# Marktag

![Coverage](/coverage_badge.svg?sanitize=true)

Flutter SDK for Marktag

## Installation 💻

Install via `flutter pub add`:

```sh
dart pub add marktag
```

The visit the Marktag Docs to see how to integrate it in your project:

### [Marktag Docs](https://markopolo-inc.github.io/marktag-docs/)

## Publishing a new version 🚀

1. Bump the `version` in `pubspec.yaml` and add a matching entry to `CHANGELOG.md`.
2. Validate the package (no changes are published):

   ```sh
   flutter pub publish --dry-run
   ```

3. Commit the version bump so you publish from a clean git state:

   ```sh
   git add pubspec.yaml CHANGELOG.md && git commit -m "chore: release <version>"
   ```

4. Publish to pub.dev:

   ```sh
   flutter pub publish
   ```

5. Tag the release and push:

   ```sh
   git tag v<version>
   git push && git push --tags
   ```
