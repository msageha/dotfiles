---
paths:
  - "**/*.py"
  - "**/requirements.txt"
  - "**/pyproject.toml"
  - "**/Pipfile"
---
# Python

- Code Style: Target Python 3.13+ unless the project pins an older version. Follow Google guidelines for naming and formatting.
- Type Hints: Use type annotations with mypy compatibility.
- Data Models: Use pydantic BaseModel (not dataclasses) for strict typing and validation, and StrEnum (3.11+) for enums. Write a description for every Field; add a default only when the field is genuinely optional (a default on a required field silently makes it optional).
- Abstractions: Pick either typing.Protocol or abc.ABC and use it consistently within a repository; default to Protocol for new code.
- Documentation: Basically not need to generate docstrings. If specified, use Google style docstrings for functions and classes.
- Error Handling: Use specific exception types, and context managers for resources.
- Imports: Organize imports by standard library, third-party, and local modules.
- Logging: Use logging instead of print for diagnostics.
- Testing: Use pytest with fixtures and parameterization, following the project's existing test layout.
