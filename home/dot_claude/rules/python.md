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
- Data Models: Use pydantic for strict typing and validation, and StrEnum for enums. Write a description and a default value for every Field.
- Documentation: Basically not need to generate docstrings. If specified, use Google style docstrings for functions and classes.
- Error Handling: Use specific exception types, and context managers for resources.
- Imports: Organize imports by standard library, third-party, and local modules.
- Logging: Use logging instead of print for diagnostics.
- Testing: Use pytest with fixtures and parameterization, following the project's existing test layout.
