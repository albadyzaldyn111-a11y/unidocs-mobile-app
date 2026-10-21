# UniDocs Mobile App

A Flutter mobile client for UniDocs, designed to provide a focused university document and workflow experience on Android and other supported platforms.

## Highlights

- Flutter application architecture with separated presentation, domain, and data concerns.
- Arabic and English localization support.
- Authentication and profile flows connected to the UniDocs API.
- Reusable UI components and typed client-side models.
- Unit, widget, and integration-test foundations.

## Technology stack

- Flutter and Dart
- Android tooling and Gradle
- REST API integration
- Flutter localization
- Automated tests

## Run locally

```bash
git clone https://github.com/albadyzaldyn111-a11y/unidocs-mobile-app.git
cd unidocs-mobile-app
flutter pub get
flutter analyze
flutter test
flutter run
```

Configure the API base URL using the project configuration documented in the source before connecting to a local or hosted backend.

## Project layout

```text
lib/               # application source
assets/            # images and bundled resources
android/           # Android platform project
test/              # unit and widget tests
integration_test/  # end-to-end test foundations
```

## Security and privacy

No production credentials or user data belong in this repository. Use local configuration or CI secrets for API endpoints, signing keys, and deployment values.

## Status

Active engineering project. Features and API contracts may change as the UniDocs platform evolves.
