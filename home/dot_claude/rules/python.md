---
paths:
  - "**/*.py"
  - "**/requirements.txt"
  - "**/pyproject.toml"
  - "**/Pipfile"
---
# Python

The library and layout choices below (pydantic, `models.py`, `base.py`, `errors.py`, `settings.py`) are defaults for new code; the ORM bullets apply only to projects that already use SQLAlchemy. In an existing project, follow the stack and layout already in use; do not introduce or replace them unilaterally.

- Code Style: Target Python 3.13+ unless the project pins an older version. Follow the project's formatter / linter configuration (ruff, black, isort); without one, PEP 8 with ruff defaults. When a lint rule conflicts with the output a function must produce, keep the output and rethink the function's design; if the rule simply does not fit that file or line, exclude it there (`# noqa: <code>`, `per-file-ignores`) rather than distorting the output (e.g. full-width substitutes for half-width characters).
- Type Hints: Annotate all function signatures. Keep the project's configured type checker (pyright / ty / mypy) clean by fixing the types, not by adding ignore comments.
- Data Models: Use pydantic BaseModel (not dataclasses or NamedTuple) for data structures, and StrEnum (3.11+) for any fixed set of string constants (model IDs, kinds). When the members mirror values accepted by an external tool (model IDs, permission modes), enumerate every value accepted across the supported version range, verified against primary sources, not only the latest generation. Write a description for every Field; add a default only when the field is genuinely optional (a default on a required field silently makes it optional).
- LLM Output Schemas: When a pydantic model is the JSON schema handed to an LLM (claude / codex CLI structured output, API tool schema), express constraints as `Field(pattern=..., max_length=..., ge=...)` so they reach the model through the schema; do not move them into `field_validator` post-checks or strip them from the emitted schema.
- ORM (SQLAlchemy): Declare every column with `mapped_column(...)`, stating `primary_key` / `nullable` / `unique` / `index` / `ForeignKey` inline rather than in `__table_args__`. Relate tables through the surrogate integer primary key and keep domain identifiers as separately named columns. Name each table and its ORM module after the domain model it persists, and store each piece of data in exactly one table.
- ORM Types: Store JSON with the dialect-native type (`JSON().with_variant(JSONB(), "postgresql")`), never as `str`; model list-valued data as a child table with a `ForeignKey`, not a JSON array. Store timestamps tz-aware in UTC with the library `TIMESTAMP` type. Validate enums in Python, not as DB CHECK / native enum constraints (each new member would need a migration).
- Abstractions: Pick either typing.Protocol or abc.ABC and use it consistently within a repository; default to Protocol for new code.
- Layout: Put pydantic `BaseModel` subclasses in the package's `models.py` and keep that file free of logic (functions, factories, compiled regexes); put `Protocol` / ABC bases in `base.py`; use the same file layout in every package. Create a package directory only when it holds at least two modules; a single module stays a `.py` file.
- Documentation: Write docstrings only when asked or when they state a contract the signature cannot express (raised exceptions, invariants); use Google style.
- Error Handling: Use specific exception types, and context managers for resources.
- Exception Classes: Define each layer's exception classes in that layer's existing exceptions module (`errors.py` when creating one) and import them; do not define exceptions inside implementation modules. Keep each layer's hierarchy independent of other layers' bases.
- Runtime Config: In applications that read environment-driven configuration, use a `BaseSettings` class (pydantic-settings) in the package's `settings.py` and instantiate it at module level there, so importing `settings` fails fast on a missing or invalid value; keep that failure in `settings.py` rather than `main`, and do not add a CLI flag for a value the settings already expose.
- Imports: Organize imports by standard library, third-party, and local modules.
- Logging: Use logging for diagnostics; reserve print (or rich) for CLI user-facing output. Keep log design lean: no duplicate messages for the same event across layers.
- Generated Text: Build multi-line output (Markdown, reports, prompts) as a triple-quoted f-string, wrapped in `textwrap.dedent` when it is indented, instead of list-append-and-join, wherever the template stays readable.
- Conditions and Loops: Prefer a plain loop or an early return over generator-plus-`next()` one-liners, and rewrite negated compound conditions (`if not (a or b)`) into positive form or a named boolean so the intent reads from the code.
- Shared State: Do not thread mutable objects (clients, accumulators) through a call chain for callees to mutate; hold them on the owning object (`self`) so side effects are visible in one place.
- Testing: Use pytest with fixtures and parameterization, following the project's existing test layout and naming; keep `tests/` mirroring the `src/` package layout, and when you move source, move its tests with it.
