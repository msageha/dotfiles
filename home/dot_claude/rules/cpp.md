---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.h"
  - "**/*.hpp"
  - "**/CMakeLists.txt"
---
# C++

- Modern C++: Use C++17/20 features (auto, lambdas, smart pointers, ranges).
- Memory Management: Use RAII principles. Prefer smart pointers over raw pointers.
- Error Handling: Use exceptions for exceptional cases. Return std::optional/expected for recoverable failures.
- Classes: Follow rule of 0/3/5. Implement proper constructors and destructors.
- Concurrency: Use std::thread, std::async, and std::mutex for thread-safe operations.
- Templates: Use concepts (C++20) or SFINAE for compile-time constraints.
- STL: Utilize appropriate containers and algorithms from the standard library.
- Move Semantics: Implement proper move constructors and assignment operators.
- Const Correctness: Use const appropriately for member functions and parameters.
- Naming: Follow consistent naming conventions for classes, functions, and variables.
- Comments: Include doxygen-style comments for public interfaces.
- Build System: Include CMake configuration for cross-platform builds.
- Testing: Include unit tests using GoogleTest or Catch2.
- Include proper error messages and validation for user inputs.
- Avoid macro usage except for include guards (prefer #pragma once).
