---
name: docx
description: "Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extraction. When Claude needs to work with professional documents (.docx files) for: (1) Creating new documents, (2) Modifying or editing content, (3) Working with tracked changes, (4) Adding comments, or any other document tasks"
license: Proprietary. LICENSE.txt has complete terms
---

# DOCX Toolkit

Use this skill for Word document creation, extraction, OOXML edits, tracked
changes, comments, formatting preservation, and document-to-image conversion.

## Choose Path

- Read/analyze text: convert with `pandoc --track-changes=all input.docx -o
  current.md`.
- Create new document: read relevant parts of `docx-js.md`, then use
  JavaScript `docx` (`Document`, `Paragraph`, `TextRun`, `Packer`).
- Edit your own/simple document: use OOXML helpers from `ooxml.md` and
  `scripts/document.py`.
- Edit third-party, legal, business, academic, or government docs: use tracked
  changes workflow.
- Comments, media, metadata, complex formatting: unpack and inspect raw OOXML.
- Visual review: convert DOCX to PDF with LibreOffice, then PDF pages to images
  with Poppler.

## References

Open only what task needs:

- `docx-js.md`: document creation syntax, styles, lists, tables, page breaks.
- `ooxml.md`: unpack/edit/pack, Document library, comments, tracked changes,
  validation, raw XML patterns.

## Scripts

- `ooxml/scripts/unpack.py <office_file> <output_dir>`
- `ooxml/scripts/pack.py <input_dir> <office_file>`
- `ooxml/scripts/validate.py <office_file>`
- `scripts/document.py`: high-level OOXML document editing library.

Run script `--help` first when available.

## Tracked Changes Workflow

1. Convert source to markdown with tracked changes visible.
2. Identify all requested edits and group into small batches by section, type,
   or proximity.
3. Read relevant `ooxml.md` sections for Document library and tracked-change
   patterns, then unpack the DOCX.
4. Before each batch, grep `word/document.xml` for current target text; markdown
   line numbers do not map to XML.
5. Mark only changed text with `<w:del>`/`<w:ins>`. Preserve unchanged runs
   where practical so redlines stay reviewable.
6. Pack, convert back to markdown, validate all intended edits, and check no
   unintended text changed.

## Code Style

Keep scripts short, deterministic, and low-noise. Avoid broad rewrites of OOXML.
Batch changes so failures are easy to isolate.
