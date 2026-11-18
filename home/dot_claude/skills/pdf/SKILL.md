---
name: "pdf"
description: "Creates, edits, and checks PDF files locally: generating, filling forms, extracting text and tables, merging / splitting / rotating, OCR, and rendering pages to PNG (「PDF を作って」「フォームに記入して」「PDF から表を抜き出して」). To just read a PDF, use the Read tool with pages first; for conversion (to Markdown / Word / HTML / images) or compression through a Stirling PDF server, use stirling-pdf where available."
allowed-tools: Read, Grep, Glob, Bash(pdftoppm:*), Bash(pdftotext:*), Bash(pdfimages:*), Bash(qpdf:*)
argument-hint: "[file path or description of PDF task]"
---

# PDF Skill

## Visual review

Whenever you created or modified a PDF for delivery (generation, form filling, layout changes), render its pages to PNG and view them yourself (Read the PNG files), and again after each meaningful update. Extraction-only tasks do not need it.

- Render with `pdftoppm` (from Poppler), or `pypdfium2` if Poppler is unavailable.
- Deliver only when the render shows no formatting defects, such as: clipped text, overlapping elements, broken tables or unreadable glyphs; inconsistent typography, spacing, margins or section hierarchy; blurry, misaligned or unlabeled charts, tables and images; broken headers / footers, page numbering or section transitions; leftover placeholder strings; filled form values outside their fields.
- Only when neither renderer is available and installing one is not approved, deliver with an explicit note that visual review was not done, and give the user the render command to check locally.

## Dependencies

Check availability first. Before installing anything, `uv run --with` included, show the command and get the user's go-ahead. For Python packages, prefer `uv run --no-project --with <pkg> python <script>`, which runs in an ephemeral environment (without `--no-project`, `uv run` inside a project creates or updates its `.venv` and `uv.lock`), over `uv pip install` into the project environment; system tools come from `brew` / `apt-get`. Install commands are in `references/recipes.md`.

## Quick Reference

| Task | Best Tool |
|---|---|
| Extract text | `pdfplumber` (layout-aware) or `pypdf` |
| Extract tables | `pdfplumber` (`.extract_tables()`) |
| Create new PDF | `reportlab` |
| Merge PDFs | `pypdf` or `qpdf` |
| Split PDF | `pypdf` or `qpdf` |
| Rotate pages | `pypdf` |
| Fill fillable forms | `pypdf` |
| Fill non-fillable forms | `reportlab` overlay or annotation-based |
| OCR scanned PDF | `pytesseract` + `pdf2image` |
| Render to images | `pdftoppm` (Poppler) or `pypdfium2` |
| Encrypt/decrypt | `pypdf` or `qpdf` |
| Watermark | `pypdf` (merge overlay) |
| Extract images | `pdfimages` (Poppler) or `pypdf` |

## Gotchas

- Japanese text: reportlab's standard fonts (Helvetica etc.) have no CJK glyphs, so Japanese renders as black boxes. Register `UnicodeCIDFont("HeiseiKakuGo-W5")` (not embedded; the viewer substitutes a local font) or a TrueType-outline `.ttf` via `TTFont` (embedded; CFF-outline `.otf` is rejected), then render to PNG and confirm no boxes remain. Code is in `references/recipes.md`.
- Sub/superscripts: Unicode subscript/superscript characters render as black boxes in reportlab. Use `<sub>` and `<super>` XML tags within Paragraph objects instead.
- Dashes: Use ASCII hyphens only; Unicode dashes (U+2011 etc.) can render as black boxes.

## Reference files (read only when needed)

- `references/recipes.md` -- install commands and code snippets for text/table extraction, merge, split, reportlab generation (including Japanese font registration), form filling, OCR, and rendering. Read when you need the exact API calls for one of these operations or are writing a generation script that contains Japanese.

## Output Conventions

- Use a temporary directory (`$TMPDIR` or the OS temp dir) for intermediate files, never the working tree; delete them when done.
- Write final artifacts to the user-specified location or current directory.
- Keep filenames stable and descriptive.
