---
name: "pdf"
description: "Creates, edits, and checks PDF files locally with Python libraries and Poppler: generating PDFs with reportlab, filling forms, extracting text and tables programmatically, merging / splitting / rotating, OCR, and rendering pages to PNG for visual review. Use when the user asks to generate or fill a PDF, extract structured data from one, or verify a PDF's layout (「PDF を作って」「フォームに記入して」「PDF から表を抜き出して」). To just read a PDF, use the Read tool with pages first. For conversions through a Stirling PDF server (PDF to Markdown / Word / HTML / images, compression), use stirling-pdf where available."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "[file path or description of PDF task]"
---

# PDF Skill

## When to Use

- Create PDFs programmatically with reliable formatting.
- Extract text, tables, or images from existing PDFs when the result feeds a script or needs structure (for just reading the content, the Read tool with `pages` is enough and needs no dependencies).
- Merge, split, or rotate PDF pages.
- Fill PDF forms (fillable and non-fillable).
- OCR scanned PDFs to make them searchable.
- Encrypt/decrypt or add watermarks.
- Validate final rendering before delivery.

## Workflow

1. **Visual review**: Render PDF pages to PNGs and view them yourself (Read the PNG files).
   - Use `pdftoppm` (from Poppler), or `pypdfium2` if Poppler is unavailable.
   - Do this yourself whenever you created or modified a PDF for delivery (generation, form filling, layout changes). Extraction-only tasks do not need it.
   - Only when neither renderer is available and installing one is not approved, deliver with an explicit note that visual review was not done, and give the user the render command to check locally.
2. **Create PDFs**: Use `reportlab` for generation.
3. **Extract text**: Use `pdfplumber` or `pypdf` for text extraction.
4. **Manipulate**: Use `pypdf` for merge/split/rotate, `qpdf` for advanced operations.
5. **Validate**: After each meaningful update, re-render pages and verify alignment, spacing, and legibility.

## Dependencies

Check availability first. Before installing anything, show the command and get the user's go-ahead. For Python packages, prefer `uv run --with <pkg> python <script>`, which leaves the project's dependencies untouched, over `uv pip install` into the project environment; system tools come from `brew` / `apt-get`. Install commands are in `references/recipes.md`.

## Quick Reference

| Task | Best Tool |
|---|---|
| Read/extract text | `pdfplumber` (layout-aware) or `pypdf` |
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

- **Japanese text**: reportlab's standard fonts (Helvetica etc.) have no CJK glyphs, so Japanese renders as black boxes. Register `UnicodeCIDFont("HeiseiKakuGo-W5")` (not embedded; the viewer substitutes a local font) or a TrueType-outline `.ttf` via `TTFont` (embedded; CFF-outline `.otf` is rejected), then render to PNG and confirm no boxes remain. Code is in `references/recipes.md`.
- **Sub/superscripts**: Unicode subscript/superscript characters render as black boxes in reportlab. Use `<sub>` and `<super>` XML tags within Paragraph objects instead.
- **Dashes**: Use ASCII hyphens only; Unicode dashes (U+2011 etc.) can render as black boxes.

## Reference files (read only when needed)

- `references/recipes.md` -- install commands and code snippets for text/table extraction, merge, split, reportlab generation (including Japanese font registration), form filling, OCR, and rendering. Read when you need the exact API calls for one of these operations or are writing a generation script that contains Japanese.

## Quality Expectations

- Consistent typography, spacing, margins, and section hierarchy.
- No rendering issues: clipped text, overlapping elements, broken tables, or unreadable glyphs.
- Charts, tables, and images must be sharp, aligned, and clearly labeled.
- Citations must be human-readable; never leave placeholder strings.

## Output Conventions

- Use a temporary directory (`$TMPDIR` or the OS temp dir) for intermediate files, never the working tree; delete them when done.
- Write final artifacts to the user-specified location or current directory.
- Keep filenames stable and descriptive.

## Final Checks

- Do not deliver until visual inspection (PNG rendering) shows zero formatting defects, except in the no-renderer case described in Workflow step 1.
- Confirm headers/footers, page numbering, and section transitions look polished.
- For form filling: convert output back to images and verify field values are correctly placed.
