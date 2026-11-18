---
paths:
  - "**/*.py"
  - "**/*.ts"
  - "**/*.go"
  - "**/*.sh"
  - "**/*.js"
  - "**/*.dart"
  - "**/*.rs"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.mjs"
  - "**/*.cjs"
  - "**/*.mts"
  - "**/*.cts"
  - "**/*.astro"
  - "**/*.swift"
  - "**/*.kt"
  - "**/*.java"
  - "**/*.rb"
  - "**/*.cs"
  - "**/*.c"
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.h"
  - "**/*.hpp"
  - "**/*.hxx"
  - "**/*.sh.tmpl"
  - "**/*.bash"
  - "**/*.bats"
  - "**/*.fish"
  - "**/*.fish.tmpl"
  - "**/*.ps1"
  - "**/*.ps1.tmpl"
  - "**/*.psm1"
---
# Code Design (code smells and their fixes in any programming language)

## How to apply

Each item under "Smells and fixes" describes a common code smell and how to fix it. The items are examples of the standard in AGENTS.md「コード」 (simple, readable code without over-engineering), not a checklist that overrides it:

- Restructure only when the result is easier to read and change, and add no function, type, interface or layer that AGENTS.md「コード」 would not justify.
- Apply the items to code you write or change. For smells in existing code outside the request, propose a fix instead of making it (AGENTS.md「依頼の解釈」).
- When restructuring existing code, keep every observable behavior the request does not change: how many times, in what order and under which conditions side effects and exceptions happen, and what absent, empty and default values mean in its contract.
- Where a language rule fixes a convention that an item also touches (where to declare variables, which enum type to use), follow the language rule.

## Smells and fixes

- Functions:
  - Split a function that mixes stages with separate responsibilities (input and parsing, computation, output) into functions named after each stage, so each can be read and tested alone.
  - Keep computation apart from I/O and mutation, so the computing part returns the same result for the same input.
  - Do not hide a state change behind a name that reads as a query; name the side effect, or split the query from the command when the split keeps atomicity and failure behavior.
  - Group values that share an invariant or are always passed together as one concept (start and end, host and port) into one type.
  - Replace a boolean argument that switches between two different operations with two functions or an enum, because a call site like `f(true)` does not say what it does. Where the language has named arguments and the operation stays the same, naming the argument at the call site is enough.
- Conditionals:
  - Handle exceptional and early-exit cases first with return / continue (guard clauses), so the main path stays at the shallowest nesting.
  - Name a whole compound condition with a variable or function at the point where it is evaluated, and merge conditions that lead to the same result.
  - Replace a flag variable that only decides when a loop ends with break / return; use break when code after the loop must still run.
  - Choose the form by what the branches do: a branch that only maps a key to a value becomes a lookup table that keeps the handling of unknown keys and evaluates only the selected entry; branching on the shape or type of a value uses the language's pattern matching where it has one; a branch on a kind that selects behavior stays a switch, unless several switches on the same kind select behavior for the same responsibility, in which case each kind gets its own implementation (polymorphism), because adding a kind would otherwise need an edit in every switch.
  - When absent and empty mean the same thing in the contract, normalize once at the boundary (e.g. to an empty collection) instead of repeating the same check in every caller.
- Loops: give each loop one job, and write filtering and transformation as the language's pipeline or comprehension where that reads more directly. Move work whose result does not change per iteration (compiling a pattern, a lookup) out of the loop only when it has no side effects and cannot fail, because the loop may run zero times.
- Variables and constants:
  - Give each variable one meaning; do not reuse it for a second purpose.
  - Name a long expression with an explaining variable. Inline a temporary that only repeats a short expression when the expression has no side effects, cannot fail, and reads values that nothing between the assignment and each use changes.
  - Declare a variable as close to its first use as its required scope allows, and keep statements that belong together adjacent.
  - Replace a literal whose meaning is not obvious (`86400`) with a named constant, and a fixed set of strings (statuses, kinds) with an enum.
- Data and state:
  - Represent a status that moves through stages as one enum with explicit transitions, not a combination of booleans, so impossible combinations cannot be expressed.
  - Give a value with a format or invariant (phone number, money, ID) its own type that validates on construction when the same check would otherwise be repeated in several places.
  - Move a function that mostly reads another type's data to that type when the logic is that type's responsibility, not one caller's or one layer's.
  - Keep a value used only during one operation as a local variable or argument, not a field.
  - Avoid module-level mutable state; pass values as arguments, prefer immutable values, and let only the owner modify shared state.
- Modules and classes:
  - Split a class or module that changes for unrelated reasons (one responsibility per reason for change), and gather into one place the knowledge whose single change currently needs edits across many files.
  - Do not let callers reach through chains (`a.b().c().d()`) into another object's internals when the nearest object can own the operation; adding a forwarding method only to shorten the chain is not a fix.
  - Use inheritance only when the subtype keeps the whole contract of the parent; otherwise use composition. Collapse a parent and child that no longer differ, and merge parallel hierarchies that must grow together.
- Algorithms: replace convoluted logic with a simpler algorithm or a standard library function that gives the same result.
