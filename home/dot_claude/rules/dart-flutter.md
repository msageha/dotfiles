---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart

- Null Safety: Make a type nullable only when null is a distinct state that callers handle.
- Immutability: Prefer final fields and const constructors. Use named parameters for functions with many arguments.
- Type Annotations: Annotate public APIs and return types; locals may rely on inference (Effective Dart).
- Linting: Follow Effective Dart via analysis_options.yaml.

# Flutter for Mobile Apps

The library and architecture choices below are defaults for new (greenfield) projects.

- State Management: Use Riverpod + hooks_riverpod whenever possible.
- Widget Structure: Composition over inheritance. Split a large build() into separate widget classes (not helper methods) along the parts that rebuild independently.
- Performance: Use ListView.builder for long lists.
- Navigation/Routing: Use go_router when the app needs deep links, URL sync or nested navigation; plain Navigator with MaterialPageRoute is enough for simple flows.
- API Integration: Use dio and Retrofit for network requests.
- Data Classes: Use freezed and json_serializable.
- Asset Management: Use Flutter Gen to reference the assets declared in pubspec.yaml.
- Theme: Use ThemeData and ThemeExtensions on Material Design 3.
- Internationalization: Use Slang and flutter_localizations.
- Error Handling: Use ErrorWidget.builder for UI errors.
- Logging: Use the logger package, and Firebase Crashlytics for error reporting.
- Architecture: Organize the app by feature (`lib/features/<feature>/`), keeping each feature's presentation and data code separate, and move a repository or service to `lib/data/` once several features use it. Add a domain layer (use cases) only when it coordinates several repositories, holds logic too complex for a view model, or is reused by several view models; do not create empty layers or pass-through use cases. Presentation depends on domain and data, never the reverse.
