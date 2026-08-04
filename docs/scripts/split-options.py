#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re
import shutil
import sys


def titleize(value: str) -> str:
    return value.replace("-", " ").replace("_", " ").title()


def module_titleize(value: str) -> str:
    if value in {"root", "index"}:
        return "Overview"
    if value == "other":
        return "Other"
    return titleize(value)


def display_option_name(option_name: str, group: str, module: str) -> str:
    if not option_name.startswith("khanelinix."):
        return option_name

    if group == "root":
        return option_name

    if module == "root":
        prefix = f"khanelinix.{group}"
        return (
            option_name[len(prefix) + 1 :]
            if option_name.startswith(prefix + ".")
            else option_name
        )

    prefix = f"khanelinix.{group}.{module}"
    return (
        option_name[len(prefix) + 1 :]
        if option_name.startswith(prefix + ".")
        else option_name
    )


def main() -> None:
    if len(sys.argv) < 4:
        print("Usage: split-options.py <input_file> <output_dir> <placeholder>")
        sys.exit(1)

    input_file = pathlib.Path(sys.argv[1])
    output_dir = pathlib.Path(sys.argv[2])
    placeholder = sys.argv[3]
    root = pathlib.Path(".")

    text = input_file.read_text()
    # Regex to find headings like "# khanelinix.something"
    # Note: options-doc usually generates headings starting with #
    heading_re = re.compile(r"(?m)^(#+)\s+.*khanelinix(?:\\\.[a-zA-Z0-9_-]+)+.*$")
    matches = list(heading_re.finditer(text))

    groups: dict[str, dict[str, list[str]]] = {}
    for idx, match in enumerate(matches):
        start = match.start()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        section = text[start:end].strip()

        option_match = re.search(r"khanelinix(?:\\\.[a-zA-Z0-9_-]+)+", section)
        option_name = option_match.group(0).replace("\\.", ".") if option_match else ""
        group = "other"
        module = "other"
        if option_name.startswith("khanelinix."):
            parts = option_name.split(".")
            group = parts[1] if len(parts) > 1 else "root"
            module = parts[2] if len(parts) > 2 else "root"

        if option_name:
            display_name = display_option_name(option_name, group, module)
            if display_name and display_name != option_name:
                lines = section.splitlines()
                if lines:
                    original_heading = lines[0]
                    escaped_option_name = option_name.replace(".", "\\.")
                    lines[0] = re.sub(
                        re.escape(escaped_option_name),
                        display_name,
                        lines[0],
                        count=1,
                    )
                    if lines[0] == original_heading:
                        lines[0] = lines[0].replace(option_name, display_name)
                    section = "\n".join(lines)

        entry = section + "\n"

        groups.setdefault(group, {}).setdefault(module, []).append(entry)

    if not groups:
        # If no groups found, dump everything into 'other' or just copy the file
        groups["other"] = {"other": [text.strip() + "\n"]}

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for group in sorted(groups):
        group_title = titleize(group)
        group_dir = output_dir / group
        group_dir.mkdir(parents=True, exist_ok=True)

        for module in sorted(groups[group]):
            module_title = module_titleize(module)
            content = f"# {group_title}: {module_title}\n\n" + "\n".join(
                groups[group][module]
            )
            (group_dir / f"{module}.md").write_text(content + "\n")

        group_index_lines = [f"# {group_title}", "", "## Modules", ""]
        for module in sorted(groups[group]):
            module_title = module_titleize(module)
            group_index_lines.append(f"- [{module_title}](./{module}.md)")
        (group_dir / "index.md").write_text("\n".join(group_index_lines) + "\n")

    # Generate index.md for this section
    section_title = titleize(output_dir.name)
    index_lines = [f"# {section_title}", ""]
    for group in sorted(groups):
        index_lines.append(f"- [{titleize(group)}](./{group}/index.md)")
    (output_dir / "index.md").write_text("\n".join(index_lines) + "\n")

    # Update SUMMARY.md
    summary_path = root / "SUMMARY.md"
    summary = summary_path.read_text()

    # Create the relative path from docs root (where SUMMARY.md is) to the option files
    # output_dir is relative to where script is run (docs root during build)
    # We need paths like options/nixos/foo.md

    rel_dir = output_dir  # Assuming script runs from docs root

    placeholder_re = re.compile(rf"(?m)^(?P<indent>[ \t]*){re.escape(placeholder)}\s*$")
    match = placeholder_re.search(summary)

    if match:
        indent = match.group("indent")
        group_lines: list[str] = []
        for group in sorted(groups):
            group_lines.append(
                f"{indent}- [{titleize(group)}]({rel_dir}/{group}/index.md)"
            )
            module_indent = indent + "  "
            for module in sorted(groups[group]):
                module_title = module_titleize(module)
                group_lines.append(
                    f"{module_indent}- [{module_title}]({rel_dir}/{group}/{module}.md)"
                )
        group_lines = "\n".join(group_lines)
        summary = placeholder_re.sub(group_lines, summary, count=1)
    else:
        print(f"Warning: Placeholder {placeholder} not found in SUMMARY.md")
        # Fallback: Append? No, safest to just warn.

    summary_path.write_text(summary + "\n")


if __name__ == "__main__":
    main()
