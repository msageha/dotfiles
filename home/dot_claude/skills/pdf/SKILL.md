---
name: "pdf"
description: "Read, create, review, merge, split, fill forms, OCR, and manipulate PDF files. Use when tasks involve any PDF operation including generation, extraction, form filling, or visual review."
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [file path or description of PDF task]
---

# PDF Skill

## When to Use

- Read or review PDF content where layout and visuals matter.
- Create PDFs programmatically with reliable formatting.
- Extract text, tables, or images from existing PDFs.
- Merge, split, or rotate PDF pages.
- Fill PDF forms (fillable and non-fillable).
- OCR scanned PDFs to make them searchable.
- Encrypt/decrypt or add watermarks.
- Validate final rendering before delivery.

## Workflow

1. **Visual review**: Render PDF pages to PNGs and inspect them.
   - Use `pdftoppm` (from Poppler) if available.
   - If unavailable, ask the user to review the output locally.
2. **Create PDFs**: Use `reportlab` for generation.
3. **Extract text**: Use `pdfplumber` or `pypdf` for text extraction.
4. **Manipulate**: Use `pypdf` for merge/split/rotate, `qpdf` for advanced operations.
5. **Validate**: After each meaningful update, re-render pages and verify alignment, spacing, and legibility.

## Dependencies (install if missing)

Prefer `uv` for dependency management.

```bash
# Python packages
uv pip install reportlab pdfplumber pypdf

# System tools (for rendering)
# macOS
brew install poppler
# Ubuntu/Debian
sudo apt-get install -y poppler-utils
```

Additional tools as needed:
```bash
# For OCR
uv pip install pytesseract pdf2image
brew install tesseract  # macOS

# For advanced manipulation
brew install qpdf

# For rendering to images (alternative)
uv pip install pypdfium2
```

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

## Common Operations

### Extract Text

```python
import pdfplumber

with pdfplumber.open("input.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        print(text)
```

### Extract Tables

```python
import pdfplumber

with pdfplumber.open("input.pdf") as pdf:
    page = pdf.pages[0]
    tables = page.extract_tables()
    for table in tables:
        for row in table:
            print(row)
```

### Merge PDFs

```python
from pypdf import PdfMerger

merger = PdfMerger()
merger.append("file1.pdf")
merger.append("file2.pdf")
merger.write("merged.pdf")
merger.close()
```

### Split PDF

```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader("input.pdf")
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    writer.write(f"page_{i+1}.pdf")
```

### Create PDF with reportlab

```python
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

c = canvas.Canvas("output.pdf", pagesize=A4)
c.setFont("Helvetica", 12)
c.drawString(72, 750, "Hello, World!")
c.save()
```

**reportlab pitfall:** Never use Unicode subscript/superscript characters (they render as black boxes). Use `<sub>` and `<super>` XML tags within Paragraph objects instead.

### Fill Fillable PDF Forms

```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader("form.pdf")
writer = PdfWriter()
writer.append(reader)

# Get field names
fields = reader.get_fields()
for name, field in fields.items():
    print(f"{name}: {field}")

# Fill fields
writer.update_page_form_field_values(
    writer.pages[0],
    {"field_name": "value"},
)
writer.write("filled.pdf")
```

### OCR Scanned PDF

```python
from pdf2image import convert_from_path
import pytesseract

images = convert_from_path("scanned.pdf")
for img in images:
    text = pytesseract.image_to_string(img)
    print(text)
```

### Render PDF to Images

```bash
pdftoppm -png input.pdf output_prefix
```

## Quality Expectations

- Consistent typography, spacing, margins, and section hierarchy.
- No rendering issues: clipped text, overlapping elements, broken tables, or unreadable glyphs.
- Charts, tables, and images must be sharp, aligned, and clearly labeled.
- Use ASCII hyphens only -- avoid Unicode dashes (U+2011 etc.).
- Citations must be human-readable; never leave placeholder strings.

## Output Conventions

- Use `tmp/pdfs/` for intermediate files; clean up when done.
- Write final artifacts to the user-specified location or current directory.
- Keep filenames stable and descriptive.

## Final Checks

- Do not deliver until visual inspection (PNG rendering) shows zero formatting defects.
- Confirm headers/footers, page numbering, and section transitions look polished.
- For form filling: convert output back to images and verify field values are correctly placed.
