---
paths:
  - "**/README.md"
  - "**/docs/**/*.md"
---
# README / project docs

- Scope: Keep a README to what an entry point needs: setup, how to run, and what the code cannot tell the reader. Put feature details in dedicated docs and link to them, and leave out details and history that would need updating with every implementation change. Docs that describe the specification state current behavior (version-availability and deprecation notes for supported versions included); put measurements, comparisons and the behavior of past versions in a separate record document or the PR.
- Order: setup and usage first; guarantees, limitations and design notes after.
- Diagrams: when documenting architecture, module dependencies or a processing flow, add a Mermaid diagram (flowchart / class / ER) next to the prose.
