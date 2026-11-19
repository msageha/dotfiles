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
  - "**/*.sql"
  - "**/*.vue"
  - "**/*.svelte"
---
# Code Design (behavior to decide, code smells and fixes, any language)

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

## Behavior to decide

Requests rarely state behavior such as the following, and code that leaves it to chance breaks in real use. The items are examples, not a full list. Within what the request's purpose covers, decide each such behavior the code reaches: follow the specification, build it with the project's existing conventions and mechanisms before rule defaults, without relaxing security or correctness to match them (AGENTS.md, opening section), and in every case choose behavior that hides no failure and loses no data the contract keeps. Whether to ask first and how to report the decisions the request did not state follow AGENTS.md「依頼の解釈」 and「成果物と報告」. Do not add handling for cases that real use cannot produce (AGENTS.md「コード」); for the same gap in existing code outside the request, propose a fix.

- Inputs: For input that crosses a trust boundary, decide what happens with missing, empty and overlong values, duplicate entries or keys, and with values at and just past each limit the contract sets; do not reimplement limits that you have confirmed a validator at the same boundary already enforces.
- Failure: Decide what the caller or user sees when an operation fails and what state it leaves. Changes that must succeed together are committed together (a transaction; for a single file, an atomic replace through a temporary file in the same directory that keeps the target's permissions and ownership), and a process that may partly succeed reports which part did; when the reply of an external update is lost, treat the outcome as unknown, not failed, and look it up where the service offers a way (a status query). Messages shown to end users say what to do next where there is something to do, and do not expose internals (stack traces, queries, file paths).
- Repetition: Where the contract lets the same operation arrive again (a retried or double-submitted request, a redelivered message or webhook, a re-run of an install script), make the repeat leave the same result as one run: prefer updates that are idempotent by nature (set a value, create if absent), and where an effect must not happen twice, decide how a repeat is recognized and record it atomically with the effect (an idempotency key or a uniqueness constraint in the same transaction), so that concurrent repeats are caught too; for an effect in an external service, use that service's idempotency mechanism where it has one. Match an idempotency key only within the same caller (and tenant) and operation, and reject a reused key that comes with a different request, so that no caller receives a result stored for another caller or request, and check the caller's current authorization before returning a stored result. A new operation the user starts on purpose is not a repeat, even with the same content.
- Concurrent updates: Where two writers can update the same data, do not read, modify and write it back unguarded; use an atomic update, an update conditional on a version, or a lock that covers the whole invariant, and decide what the caller gets when a conflict is detected (tell a conflict apart from a change that was not needed).
- External calls: Make sure every network call expected to finish (not a long-lived stream) has a limit on the whole wait, from the client's configuration, a caller's deadline or a timeout you set (a timeout that only bounds the gap between received bytes does not bound the whole call), and decide what the caller sees when it expires; check the client library, since some wait indefinitely by default. Add retries only as AGENTS.md「コード」 allows.
- Time: Store and compute instants in a form that identifies the same instant everywhere (a timezone-aware UTC timestamp or the language's instant type), and convert to a user's timezone for display. Keep calendar dates (a birthday) as dates without a timezone, and recurring local times (a daily 09:00 schedule) as a local time with its timezone, because converting them to UTC changes their meaning across daylight-saving changes. Measure elapsed time and timeouts with a monotonic clock, which the wall clock's adjustments do not move.
- Money and exact decimals: Use a decimal type or integer minor units with enough precision, not binary floating point, and read values from text or integers, not through a float. Round at each step the specification defines, to its unit and rounding mode, not at other steps.
- Text encoding: Where the platform default encoding can differ from the data's encoding (Windows code pages, locale settings, subprocess output), pass the encoding explicitly: the data's own encoding for existing files and other programs' output, UTF-8 for formats you define.
- Ordering: Where output needs a stable order (lists an API returns or a screen shows, pages of results, generated files), order explicitly by the order the contract defines, keeping input or user-chosen order where that is the contract, and add a tie-breaker where equal keys would make pages or repeated runs differ; a query without ORDER BY and iteration over a hash set have no guaranteed order.
- Growing collections: Where real data can make a fetched list unbounded (records, logs, uploads), limit how many items are fetched and held at once (pages, or a limit in the query), with a maximum on any page size the caller can choose, and where the result goes back to the caller in pages, tell it whether more remain; where the contract is the whole set (an export), process it batch by batch, writing each batch out, instead of truncating it.
- Authorization: Check on the trusted side (the server, not the client), with the project's existing policy, that the caller may perform that operation on that resource, and restrict lists, searches and aggregates to what the caller may see when fetching them; hiding a control in the UI is not a check, and an ID in a request does not prove ownership. Where you have confirmed that a shared layer at the same trust boundary (middleware) checks the same caller, operation and resource on every path, do not add the same check to each handler; keep checks at other layers (row-level security in the database) that the project has on purpose. When an authorization or validation check cannot reach a decision (its policy service fails or times out), deny the request.
- Stored formats: When a change alters a stored schema or file format, check whether existing data that must be kept still reads correctly, and when it does not, include its conversion through the project's migration path in the same change instead of code that keeps reading both forms, which AGENTS.md「コード」 allows only when compatibility is requested. Where old and new versions of the code run against the same data during a deployment and cannot all read and write it as it is, that coexistence is itself a compatibility requirement: split the change into steps in which every running version can read the data, read what the other versions write, and keep what they write when it rewrites a record, and remove the support for the old form in the last step. Whether a change that breaks data or callers outside the repository needs confirmation follows AGENTS.md「コード」.
