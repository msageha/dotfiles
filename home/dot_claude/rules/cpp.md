---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.hpp"
  - "**/*.hxx"
  - "**/CMakeLists.txt"
---
# C++

- Modern C++: Use C++17/20 features where the toolchain allows (auto, lambdas, ranges, concepts).
- Memory Management: Use RAII. Prefer smart pointers over owning raw pointers.
- Error Handling: Use exceptions for exceptional cases. Return std::optional/std::expected for recoverable failures.
- Macros: Avoid macro usage; prefer #pragma once over include guards.
- Comments: Doxygen-style comments for public interfaces only; do not comment what the code already says.
- Build System: Integrate into the project's existing build system (CMake etc.); do not introduce a new one unilaterally.
- Testing: Use the project's established framework (GoogleTest, Catch2, ...) and match existing test patterns.
