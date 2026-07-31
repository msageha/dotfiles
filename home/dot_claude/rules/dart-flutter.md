---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart

- Null Safety: Use nullable types only when necessary.
- Immutability: Prefer final fields and const constructors. Use named parameters for functions with many arguments.
- Code Organization: Follow feature-based structure with proper exports.
- Type Annotations: Annotate public APIs and return types; locals may rely on inference (Effective Dart).
- Linting: Follow Effective Dart via analysis_options.yaml.

# Flutter for Mobile Apps

- State Management: Use Riverpod + hooks_riverpod whenever possible.
- Widget Structure: Composition over inheritance. Break UI into small, reusable widgets.
- Performance: Use const constructors. Use ListView.builder for long lists.
- Navigation/Routing: Use Beamer for complex navigation.
- API Integration: Use dio and Retrofit for network requests.
- Data Classes: Use freezed and json_serializable.
- Asset Management: Use Flutter Gen with proper asset organization in pubspec.yaml.
- Theme: Use ThemeData and ThemeExtensions on Material Design 3.
- Internationalization: Use Slang and flutter_localizations.
- Error Handling: Use ErrorWidget.builder for UI errors.
- Logging: Use the logger package, and Firebase Crashlytics for error reporting.
- Architecture: Follow clean architecture principles (domain, data, presentation layers).
- Testing: Follow the project's existing test setup (Mocktail mocks, widget / integration / golden tests where established).
