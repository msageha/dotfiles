---
paths:
  - "**/*.py"
  - "**/requirements.txt"
  - "**/pyproject.toml"
  - "**/Pipfile"
---
# Python

- Code Style: Version 3.11 or latest. Follow Google guidelines for naming and formatting.
- Type Hints: Use type annotations with mypy compatibility.
- Documentation: Basically not need to generate docstrings. If specified, use Google style docstrings for functions and classes.
- Error Handling: Use specific exception types with proper context managers.
- OOP: Follow SOLID principles. Use dataclasses or named tuples for data containers.
- Functional Features: Utilize list comprehensions, generators, and higher-order functions.
- Imports: Organize imports by standard library, third-party, and local modules.
- Asynchronous Code: Use async/await with asyncio for I/O-bound operations.
- Testing: Include pytest tests with fixtures and parameterization.
- Logging: Implement proper logging instead of print statements.
- Context Managers: Use with statements for resource management.
- For Data Science: Follow pandas, numpy, and matplotlib best practices.
- Include proper error messages and validation for user inputs.
