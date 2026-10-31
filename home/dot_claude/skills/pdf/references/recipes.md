# PDF Recipes

Contents: Install Commands / Extract Text / Extract Tables / Merge / Split / Create with reportlab / Japanese Text in reportlab / Fill Fillable Forms / OCR / Render to Images

## Install Commands

Run these only after showing the command and getting the user's go-ahead (see SKILL.md "Dependencies").

```bash
# One-off script without touching the project's dependencies
uv run --with reportlab --with pdfplumber --with pypdf python script.py

# Into the project environment
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

## Extract Text

```python
import pdfplumber

with pdfplumber.open("input.pdf") as pdf:
    for page in pdf.pages:
        text = page.extract_text()
        print(text)
```

## Extract Tables

```python
import pdfplumber

with pdfplumber.open("input.pdf") as pdf:
    page = pdf.pages[0]
    tables = page.extract_tables()
    for table in tables:
        for row in table:
            print(row)
```

## Merge

```python
from pypdf import PdfWriter

writer = PdfWriter()
writer.append("file1.pdf")
writer.append("file2.pdf")
writer.write("merged.pdf")
writer.close()
```

## Split

```python
from pypdf import PdfReader, PdfWriter

reader = PdfReader("input.pdf")
for i, page in enumerate(reader.pages):
    writer = PdfWriter()
    writer.add_page(page)
    writer.write(f"page_{i+1}.pdf")
```

## Create with reportlab

```python
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

c = canvas.Canvas("output.pdf", pagesize=A4)
c.setFont("Helvetica", 12)
c.drawString(72, 750, "Hello, World!")
c.save()
```

## Japanese Text in reportlab

Helvetica and the other standard fonts have no CJK glyphs, so Japanese comes out as black boxes. Register a Japanese font first.

```python
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.cidfonts import UnicodeCIDFont
from reportlab.pdfbase.ttfonts import TTFont

# CID font: no font file needed, but not embedded (the viewer substitutes a local Japanese font)
pdfmetrics.registerFont(UnicodeCIDFont("HeiseiKakuGo-W5"))  # gothic; "HeiseiMin-W3" for mincho
c.setFont("HeiseiKakuGo-W5", 12)

# Embedded font: needs a TrueType-outline .ttf / .ttc file
pdfmetrics.registerFont(TTFont("JP", "/path/to/font.ttf"))
c.setFont("JP", 12)
```

`TTFont` rejects CFF-outline fonts (most `.otf`, and Hiragino `.ttc` on macOS) with "postscript outlines are not supported"; pick a TrueType-outline font instead. For `Paragraph`, set the registered name as the style's `fontName`.

## Fill Fillable Forms

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

## OCR

```python
from pdf2image import convert_from_path
import pytesseract

images = convert_from_path("scanned.pdf")
for img in images:
    text = pytesseract.image_to_string(img)
    print(text)
```

## Render to Images

```bash
pdftoppm -png input.pdf output_prefix
```
