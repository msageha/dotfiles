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

Each item under "Smells and fixes" describes a code smell and how to fix it, together with the conditions under which the fix keeps behavior or helps readability. The items are examples of the standard in AGENTS.md「コード」 (simple, readable code without over-engineering), not a checklist that overrides it:

- Restructure only when the result is easier to read and change, and add no function, type, constant, interface or layer that AGENTS.md「コード」 would not justify.
- Apply the items to code you write or change. For smells in existing code outside the request, propose a fix instead of making it (AGENTS.md「依頼の解釈」).
- When restructuring existing code, keep every observable behavior the request does not change: how many times, in what order and under which conditions side effects and exceptions happen, and what absent, empty and default values mean in its contract.
- Where a language rule fixes a convention that an item also touches (when to use an enum and which kind, how to split UI code), follow the language rule.

## Smells and fixes

- Functions:
  - Keep computation apart from I/O and mutation, so the computing part returns the same result for the same input.
  - Do not hide a state change behind a name that reads as a query; name the side effect, or split the query from the command when the split keeps atomicity and failure behavior.
  - Replace a boolean argument that switches between two different operations with two functions or an enum, because a call site like `f(true)` does not say what it does. Where the language has named arguments and the operation stays the same, naming the argument at the call site is enough.
  - Group values into one type when they share an invariant (an end that must not precede its start) or are validated, serialized or passed on as one unit (a request body, a configuration). Pass other values as separate arguments, named where the language allows, even when there are many.
- Conditionals:
  - Name a compound condition whose intent does not read from the expression with a boolean variable where it is evaluated; make it a function only when several places use it.
  - Replace a flag variable that only decides when a loop ends with break / return; use break when code after the loop must still run.
  - Choose the form of a branch by what it does:
    - It only maps a key to a value: use a lookup table, provided the table accepts the same keys with the same comparison, keeps the handling of unknown keys, and evaluates only the selected entry.
    - It depends on the shape or type of a value: use the language's pattern matching where the supported version has it the patterns match exactly what the original checks matched (a class pattern can also match subclasses that an exact type check rejected), and reading the value fewer or more times has no side effects.
    - It selects behavior by kind: keep a switch. When the same selection is duplicated in several places, gather it into one place first, and give each kind its own implementation (polymorphism) only when that reduces the places a new kind must touch. Separate operations that each switch exhaustively over the kinds stay as they are.
  - When absent and empty mean the same thing in the contract, normalize once at the boundary (e.g. to an empty collection) instead of repeating the same check in every caller.
- Loops and temporaries:
  - Move work whose result does not change per iteration out of the loop only when it has no side effects, cannot fail (the loop may run zero times), and does not create an object that each iteration must get anew (a fresh list or buffer).
  - Inline a temporary that only repeats a short expression only when the expression has no side effects, cannot fail, reads only values that nothing between the assignment and each use changes, and yields a result that no code relies on being one shared object.
- Data and state:
  - Represent a status as one type whose values are the possible states, not a combination of booleans, so impossible combinations cannot be expressed.
  - Give a fixed set of values that the code passes around and branches on (statuses, kinds) a dedicated type (an enum, or the language's equivalent such as a union of string literals) instead of bare strings. A value read once from outside and handled in a single branch with a fallback for unknown values can stay a string, and so can values in a language without such a type (shell scripts), branched on with `case`.
  - Give a value with a format or invariant (phone number, money, ID) its own type that validates on construction only when the same check would otherwise be repeated in several places.
  - Give mutable state (clients, accumulators) one owner that holds and modifies it, so side effects are visible in one place: do not pass internal state down through layers for callees to mutate (a destination the caller chooses, such as an output writer or a transaction, is still passed as an argument), and keep it at module or global level only when it must outlive one call (a shell session's state), updated through its owner. A value whose lifetime ends with one call stays a local variable or argument, not a field; a setting the owner was created with stays a field even when one operation reads it.
  - Do not let callers reach through chains (`a.b().c().d()`) into another object's internals when the nearest object can own the operation; adding a forwarding method only to shorten the chain is not a fix. Fluent APIs that return the same kind of object (query and request builders) are not such chains.
