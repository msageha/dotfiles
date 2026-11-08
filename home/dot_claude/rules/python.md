---
paths:
  - "**/*.py"
  - "**/requirements.txt"
  - "**/pyproject.toml"
  - "**/Pipfile"
---
# Python

The ORM bullets apply only to projects that already use SQLAlchemy.

- Code Style:
  - Target Python 3.13+ unless the project pins an older version.
  - Without a project formatter / linter configuration, follow PEP 8 with ruff defaults.
  - Suppression syntax, for the cases AGENTS.md「コード」 allows, always naming the rule: `# noqa: <code>` or `per-file-ignores` for ruff, `# pyright: ignore[<rule>]` for pyright, `# ty: ignore[<rule>]` for ty, and `# type: ignore[<code>]` only for mypy (pyright treats any `# type: ignore` as suppressing the whole line).
- Type Hints: Annotate all function signatures, and keep the project's configured type checker (pyright / ty / mypy) clean by fixing the types.
- Data Models:
  - Use pydantic BaseModel (not dataclasses) for data that is validated or serialized: LLM output, request and response bodies, settings, and persisted JSON. An immutable group of values passed between functions in the same process can be a NamedTuple.
  - Use StrEnum (3.11+) for any fixed set of string constants (model IDs, kinds). When the members mirror values accepted by an external tool (model IDs, permission modes), enumerate every value accepted across the supported version range, verified against primary sources, not only the latest generation. Keep such an enum even when only one place uses it or a bool would currently be enough to choose between its members: it names the accepted values.
  - Write a description for every field of a pydantic model, on the Field or on the docstring of the enum or model the field is typed with; add a default only when the field is genuinely optional (a default on a required field silently makes it optional).
  - Make a field or column Optional / nullable only when "no value" must be told apart from every real value; otherwise represent it with a default such as `""`.
- LLM Output Schemas: When a pydantic model is the JSON schema handed to an LLM (claude / codex CLI structured output, API tool schema), express constraints as `Field(pattern=..., max_length=..., ge=...)` so they reach the model through the schema; do not move them into `field_validator` post-checks or strip them from the emitted schema. When the schema builder inlines `$ref` with the field's own keys taking precedence, a Field description replaces the description of the enum or model it refers to, so describe such a field in one place: in the type's docstring, or in the Field description together with the meanings of the values.
- ORM (SQLAlchemy):
  - Declare every column with `mapped_column(...)`, stating `primary_key` / `nullable` / `unique` / `index` / `ForeignKey` inline where `mapped_column` can express them; use `__table_args__` for the rest (constraints and indexes over several columns, indexes with a name or a condition, table options).
  - Relate tables through the surrogate integer primary key and keep domain identifiers as separately named columns.
  - Name each table and its ORM module after the domain model it persists, and store each piece of data in exactly one table.
- ORM Types:
  - Store JSON with the dialect-native type (`JSON().with_variant(JSONB(), "postgresql")`), never as `str`; model list-valued data as a child table with a `ForeignKey`, not a JSON array.
  - Store timestamps tz-aware in UTC with the library `TIMESTAMP` type.
  - Keep value conditions (enum members, ranges, length limits) in Python, and do not copy them into the schema as CHECK constraints, native enums or column lengths (each change would need a migration).
- Abstractions: Add a typing.Protocol or abc.ABC base only in the cases AGENTS.md「コード」 allows, not only so that tests can swap in a fake. Use one form consistently within the repository: the one it already uses, or Protocol in a repository with neither.
- Layout:
  - Put pydantic `BaseModel` subclasses in the package's `models.py` and keep module-level logic (functions, factories, compiled regexes) out of that file; methods and properties that derive values from a model's own fields belong on the model, except conversions specific to one consumer. Put `Protocol` / ABC bases in `base.py`; use the same file layout in every package.
  - Create a package directory only when it holds at least two modules; a single module stays a `.py` file.
  - Prefix names used only inside their module with `_` (in a library, a name without `_` reads as public API that callers outside the repository may depend on), and do not make a name public only so that tests can import it.
- Documentation: Write docstrings only when asked or when they state a contract the signature cannot express (raised exceptions, invariants); use Google style, starting with a one-line summary of what it does or returns.
- Resources: Manage resources with context managers (`with`).
- Exception Classes: Define each layer's exception classes in that layer's existing exceptions module (`errors.py` when creating one) and import them; do not define exceptions inside implementation modules. Keep each layer's hierarchy independent of other layers' bases; subclass another layer's base only when that layer's contract has callers catch it.
- Runtime Config: In applications that read environment-driven configuration, define a `BaseSettings` class (pydantic-settings) in the package's `settings.py` and create it once, at module level or through a cached getter (`functools.cache`). Make a missing or invalid value fail at startup through the class's own validation (the module-level instance, or a getter call at startup), not through checks written in `main`. Read values from the settings object where they are used instead of copying them into module-level constants, which hide that the value comes from the environment, and do not add a CLI flag for a value the settings already expose.
- Logging: Use logging for diagnostics; reserve print (or rich) for CLI user-facing output. Keep log design lean: no duplicate messages for the same event across layers.
- Generated Text: Build multi-line output (Markdown, reports, prompts) as a triple-quoted f-string, wrapped in `textwrap.dedent` when it is indented, instead of list-append-and-join, wherever the template stays readable. When an f-string only joins constants that exist just to build that text, write it as one literal instead; keep constants that other text or code shares or that must match an exact string elsewhere (a parser, an external tool).
- Conditions and Loops: Prefer a plain loop or an early return over generator-plus-`next()` one-liners, and rewrite negated compound conditions (`if not (a or b)`) into positive form or a named boolean so the intent reads from the code.
- Shared State: Do not thread mutable objects (clients, accumulators) through a call chain for callees to mutate; hold them on the object that already owns them (`self`) so side effects are visible in one place.
- Testing: Use pytest with fixtures and parameterization; keep `tests/` mirroring the `src/` package layout, and when you move source, move its tests with it.
