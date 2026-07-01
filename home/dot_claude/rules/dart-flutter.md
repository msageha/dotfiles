---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart

- Null Safety: Utilize sound null safety. Use nullable types only when necessary.
- Classes: Implement proper constructors (default, named, factory). Use final for immutable fields.
- Collections: Use collection literals and operators (spread, collection if/for).
- Async: Implement async/await with Future and Stream classes appropriately.
- Error Handling: Use try/catch with specific exception types.
- Code Organization: Follow feature-based structure with proper exports.
- Extension Methods: Use extensions to add functionality to existing classes.
- Mixins: Implement mixins for shared functionality between classes.
- Parameters: Use named parameters for functions with many arguments.
- Immutability: Prefer final variables and const constructors where possible.
- Linting: Follow effective dart style guidelines with analysis_options.yaml.
- Testing: Include test cases using the test package.
- Include comprehensive type annotations for all variables and return types.

# Flutter for Mobile Apps

- State Management: Use proper state management. Use Riverpod + hooks_riverpod whenever possible.
- Widget Structure: Implement composition over inheritance. Break UI into small, reusable widgets.
- Performance: Use const constructors. Implement ListView.builder for long lists.
- Responsive Design: Use LayoutBuilder, MediaQuery, or FractionallySizedBox for responsive UIs.
- Navigation/Routing: Implement Beamer for complex navigation.
- API Integration: Use dio and Retrofit package for network requests.
- Mobile Utility: Use freezed and json_serializable for data classes.
- Asset Management: Use Flutter Gen for assets and images and proper asset organization with pubspec.yaml.
- Theme: Implement ThemeData and ThemeExtensions using Material Design 3 for consistent styling.
- Internationalization: Use Slang and flutter_localizations package for localization.
- Platform-Specific Code: Handle iOS/Android differences with Platform.isIOS checks.
- Error Handling: Implement ErrorWidget.builder for UI errors and try/catch for logic.
- Animations: Use AnimationController with Tween for custom animations.
- Gestures: Implement GestureDetector with proper feedback mechanisms.
- Testing: Include mock test using Mocktail, widget tests, integration tests, and golden tests.
- Logging: Use logger package for logging and Firebase Crashlytics for error reporting.
- Architecture: Follow clean architecture principles (domain, data, presentation layers).
