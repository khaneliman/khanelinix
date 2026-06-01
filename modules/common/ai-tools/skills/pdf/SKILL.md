---
name: pdf
description: Comprehensive PDF manipulation toolkit for extracting text and tables, creating new PDFs, merging/splitting documents, and handling forms. When Claude needs to fill in a PDF form or programmatically process, generate, or analyze PDF documents at scale.
license: Proprietary. LICENSE.txt has complete terms
---

# PDF Toolkit

Use this skill for PDF extraction, generation, splitting/merging, annotation,
form filling, visual conversion, and batch processing.

## Choose Path

- Text extraction: try `pdftotext` or `pypdf`; use `pdfplumber` for layout and
  tables.
- Merge/split/rotate/encrypt: use `qpdf` or `pypdf`.
- Create PDFs: use `reportlab`; read `reference.md` for advanced layout.
- Fill forms: read `forms.md` first and use bundled scripts.
- Visual analysis: convert pages to images with `scripts/convert_pdf_to_images.py`
  or Poppler tools.
- Scanned PDFs: OCR with `pytesseract` after image conversion.

## Bundled References

Open only when needed:

- `forms.md`: required for fillable forms and annotation workflow.
- `reference.md`: advanced `pypdfium2`, `pdf-lib`, layout, and troubleshooting.

## Bundled Scripts

Prefer scripts as black boxes; run `--help` first:

- `check_fillable_fields.py`
- `extract_form_field_info.py`
- `fill_fillable_fields.py`
- `fill_pdf_form_with_annotations.py`
- `check_bounding_boxes.py`
- `create_validation_image.py`
- `convert_pdf_to_images.py`

## Core Patterns

Minimal text extraction:

```python
from pypdf import PdfReader

reader = PdfReader("input.pdf")
text = "\n".join(page.extract_text() or "" for page in reader.pages)
```

Minimal merge:

```python
from pypdf import PdfReader, PdfWriter

writer = PdfWriter()
for path in ["a.pdf", "b.pdf"]:
    for page in PdfReader(path).pages:
        writer.add_page(page)
with open("merged.pdf", "wb") as f:
    writer.write(f)
```

## Verification

Always verify produced PDFs. For structural operations, reopen with `pypdf` and
check page count/metadata. For forms or annotations, create validation images
and inspect visible placement.
