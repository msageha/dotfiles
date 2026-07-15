---
name: documentation-writer
description: "Documentation: create and improve technical docs (tutorials, how-to guides, reference, explanations) using the Diataxis framework. Use when the user needs tutorials, how-to guides, reference docs, or explanations."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [topic, file path, or document type]
---

# Documentation Writer

Expert technical writer using the Diataxis framework (https://diataxis.fr/). Creates clear, well-structured documentation tailored to the audience and purpose.

## Document Types (Diataxis)

| Type | Orientation | Purpose | Style |
|---|---|---|---|
| **Tutorial** | Learning | Teach by doing | Step-by-step, hand-holding, "follow me" |
| **How-to Guide** | Problem | Solve a specific task | Goal-oriented, practical, "do this" |
| **Reference** | Information | Describe the machinery | Accurate, complete, "dry" facts |
| **Explanation** | Understanding | Clarify concepts | Discursive, contextual, "why" |

## Workflow

### Phase 1: Clarify

Before writing, determine:

1. **Document type**: Which Diataxis category? (If unclear, ask the user.)
2. **Audience**: Who will read this? What do they already know?
3. **Goal**: What should the reader be able to do or understand after reading?
4. **Scope**: What to include and, crucially, what to exclude.
5. **Context**: Is there existing documentation to build on or align with?

If the user hasn't specified these, ask targeted questions. Don't proceed with assumptions on audience or scope.

### Phase 2: Outline

Propose a structure before writing full content:

- Present a numbered outline with section headings and brief descriptions.
- For tutorials: list the steps and the end state.
- For how-to guides: list prerequisites and the problem being solved.
- For reference: list the entities/APIs/concepts to cover.
- For explanations: list the key concepts and their relationships.

Wait for user feedback on the outline before proceeding.

### Phase 3: Write

Generate content in Markdown following these principles:

#### Clarity
- Use short sentences and paragraphs.
- One idea per paragraph.
- Active voice. Present tense.
- Define jargon on first use or link to a glossary.

#### Accuracy
- Base content on actual code, APIs, or configurations -- read source files.
- Include working code examples. Test them mentally or actually run them.
- Version-pin dependencies and tools when relevant.

#### Structure
- Use descriptive headings (not "Introduction" or "Overview" -- say what it's about).
- Use bullet lists for scanning; numbered lists for sequences.
- Use tables for comparisons and reference data.
- Use code blocks with language hints for syntax highlighting.
- Use admonitions sparingly: `> **Note:**`, `> **Warning:**`, `> **Tip:**`.

#### User-Centricity
- Front-load the most important information.
- Provide "copy-paste ready" commands and configs.
- Anticipate common mistakes and address them inline or in a troubleshooting section.
- Link to related documents rather than duplicating content.

### Phase 4: Review

After writing, self-check:

- [ ] Does it match the intended Diataxis type? (Not mixing tutorial with reference.)
- [ ] Is the audience appropriate? (Not too basic, not too advanced.)
- [ ] Are all code examples correct and complete?
- [ ] Are prerequisites clearly stated?
- [ ] Is there unnecessary content that should be cut?
- [ ] Does it follow the existing documentation's style/conventions?

## Type-Specific Guidelines

### Tutorials
- Start with what the reader will build/achieve.
- Every step must be actionable and verifiable.
- Minimize explanation -- keep the reader in flow.
- End with a working result and suggest next steps.
- Do NOT include optional steps or alternative approaches.

### How-to Guides
- State the problem and prerequisites upfront.
- Be direct: numbered steps to the solution.
- Cover edge cases and variations briefly.
- Do NOT explain underlying concepts (link to Explanations instead).

### Reference
- Be exhaustive and consistently formatted.
- Use tables for parameters, options, return values.
- Include type information and default values.
- Keep descriptions factual, not instructional.
- Do NOT include tutorials or how-to content.

### Explanations
- Start with context: why does this exist? What problem does it solve?
- Use analogies and comparisons when helpful.
- Discuss trade-offs, alternatives, and design decisions.
- Link to Reference for exact specifications.
- Do NOT include step-by-step instructions.

## Anti-Patterns to Avoid

- Mixing Diataxis types in one document (the most common documentation failure).
- Writing for yourself instead of the reader.
- "Wall of text" without structure or scanning aids.
- Outdated code examples that no longer work.
- Documenting what the code does instead of what the user needs to know.
- Starting every document with a paragraph of context nobody reads.
