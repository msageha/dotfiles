---
name: documentation-writer
description: "Creates and improves technical documentation (tutorial, how-to guide, reference, explanation) with the Diataxis framework, choosing the type and structure for the audience. Use when the user asks for a README, guide, tutorial, API reference, or design explanation (「ドキュメントを書いて」「README を整備して」「手順書を作って」). For Japanese prose style (文体・整形・推敲), also use japanese-tech-writing where available."
allowed-tools: Read, Grep, Glob
argument-hint: "[topic, file path, or document type]"
---

# Documentation Writer

Writes documentation with the Diataxis framework (https://diataxis.fr/), tailored to the audience and purpose.

## Document Types (Diataxis)

| Type | Orientation | Purpose | Style |
|---|---|---|---|
| Tutorial | Learning | Teach by doing | Step-by-step, hand-holding, "follow me" |
| How-to Guide | Problem | Solve a specific task | Goal-oriented, practical, "do this" |
| Reference | Information | Describe the machinery | Accurate, complete, "dry" facts |
| Explanation | Understanding | Clarify concepts | Discursive, contextual, "why" |

## Workflow

### Phase 1: Clarify

Before writing, determine:

1. Document type: Which Diataxis category?
2. Audience: Who will read this? What do they already know?
3. Goal: What should the reader be able to do or understand after reading?
4. Scope: What to include and what to exclude.
5. Context: Is there existing documentation to build on or align with?

Infer whatever is unstated from the request, the existing documentation and the code, and proceed; state the inferred values as assumptions in your report to the user, not in the document. Ask only when the audience or goal can be read in ways that would produce substantially different documents and the sources do not settle it; then ask once, in one message, giving each open item as labelled options with one recommendation and what each choice changes. When the user delegates the work through to completion (e.g. 'すべて書いて'), do not ask: proceed on stated assumptions.

### Phase 2: Outline

Plan the structure before writing full content:

- Present a numbered outline with section headings and brief descriptions.
- For tutorials: list the steps and the end state.
- For how-to guides: list prerequisites and the problem being solved.
- For reference: list the entities/APIs/concepts to cover.
- For explanations: list the key concepts and their relationships.

When Phase 1 needs a question, include the outline in that same message and wait once; otherwise write without waiting for approval of the outline.

### Phase 3: Write

Generate content in Markdown following these principles:

#### Clarity
- Use short sentences and paragraphs.
- One idea per paragraph.
- Active voice. Present tense.
- Define jargon on first use or link to a glossary.

#### Accuracy
- Base content on actual code, APIs, or configurations -- read source files.
- Include working code examples. Run every example and command that can run in this environment and record the observed output / exit code; mark the rest as unverified instead of testing them mentally.
- Version-pin dependencies and tools when relevant.

#### Structure
- Use descriptive headings (not "Introduction" or "Overview" -- say what it's about).
- Use bullet lists for scanning; numbered lists for sequences.
- Use tables for comparisons and reference data.
- Use code blocks with language hints for syntax highlighting.
- Use admonitions sparingly: `> **Note:**`, `> **Warning:**`, `> **Tip:**`.

#### User-Centricity
- Document what the reader needs to know, not what the code does.
- Front-load the most important information instead of opening every document with a paragraph of background.
- Provide "copy-paste ready" commands and configs.
- Anticipate common mistakes and address them inline or in a troubleshooting section.
- Link to related documents rather than duplicating content.

### Phase 4: Review

After writing, self-check:

- [ ] Does it match the intended Diataxis type? (Not mixing tutorial with reference.)
- [ ] Is the audience appropriate? (Not too basic, not too advanced.)
- [ ] Are all code examples correct and complete (verified by running them, or explicitly marked unverified)?
- [ ] Are prerequisites clearly stated?
- [ ] Is there content this reader does not need (history, internal names, repetition) that should be cut, while the premises, reasons and examples they need stay?
- [ ] Does it follow the existing documentation's style/conventions?

## Type-Specific Guidelines

### Tutorials
- Start with what the reader will build/achieve.
- Every step must be actionable and verifiable.
- Minimize explanation -- keep the reader in flow.
- End with a working result and suggest next steps.
- Leave out optional steps and alternative approaches; they break the reader's flow. Put alternatives in a how-to guide.

### How-to Guides
- State the problem and prerequisites upfront.
- Be direct: numbered steps to the solution.
- Cover edge cases and variations briefly.
- Link to an Explanation for underlying concepts instead of explaining them inline, so the steps stay short.

### Reference
- Be exhaustive and consistently formatted.
- Use tables for parameters, options, return values.
- Include type information and default values.
- Keep descriptions factual, not instructional.
- Keep tutorials and how-to content out; link to them, so readers looking something up find only facts.

### Explanations
- Start with context: why does this exist? What problem does it solve?
- Make abstract points concrete with examples from the reader's own setting (their code, commands, data) and with comparisons to alternatives they already know. Keep the standard technical terms instead of replacing them with metaphors or coined terms; readers cannot map those back to the identifiers and documentation they search.
- Discuss trade-offs, alternatives, and design decisions.
- Link to Reference for exact specifications.
- Leave step-by-step instructions to tutorials and how-to guides and link to them.
