---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.h"
  - "**/*.hpp"
  - "**/*.hxx"
  - "**/CMakeLists.txt"
---
# C++ (`.h` headers only in C++ projects)

- Modern C++: Use C++17/20 features where the toolchain allows (auto, lambdas, ranges, concepts).
- Memory Management: Use RAII. Prefer smart pointers over owning raw pointers.
- Error Handling: Use exceptions for exceptional cases. Return std::optional (C++17) or std::expected (C++23, only when the project's standard allows) for recoverable failures.
- Macros: Avoid macro usage; prefer #pragma once over include guards.
- Comments: Comment a public interface only when its contract (preconditions, ownership, error behaviour) is not obvious from the name and signature, and use Doxygen syntax only if the project already does; beyond that, write a comment only to state constraints, invariants, or non-obvious rationale the code cannot express.
