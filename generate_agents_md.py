#!/usr/bin/env python
# /// script
# requires-python = ">=3.8"
# dependencies = [
#   "pyyaml",
# ]
# ///

"""Generate AGENTS.md from .cursor/rules directory."""

import argparse
import logging
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

try:
    import yaml
except ImportError:
    yaml = None


def setup_logging() -> None:
    """Configure logging to stderr."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s: %(message)s",
        stream=sys.stderr,
    )


def parse_frontmatter(content: str) -> Tuple[Dict[str, str], str]:
    """
    Parse YAML frontmatter from markdown content.
    
    Returns:
        Tuple of (frontmatter dict, content without frontmatter)
    """
    frontmatter_pattern = r"^---\s*\n(.*?)\n---\s*\n(.*)$"
    match = re.match(frontmatter_pattern, content, re.DOTALL)
    
    if not match:
        return {}, content
    
    frontmatter_text = match.group(1)
    content_text = match.group(2)
    
    if yaml is None:
        logging.warning("PyYAML not available, skipping frontmatter parsing")
        return {}, content_text
    
    try:
        frontmatter = yaml.safe_load(frontmatter_text) or {}
        return frontmatter, content_text
    except yaml.YAMLError as e:
        logging.warning(f"Failed to parse frontmatter: {e}")
        return {}, content_text


def extract_section_name(content: str) -> str:
    """
    Extract section name from the first level 1 heading in content.
    
    Returns:
        Section name without the # prefix, or empty string if not found
    """
    match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return ""


def read_rule_file(rule_path: Path) -> Tuple[str, Dict, str]:
    """
    Read a RULE.md file and extract section name, frontmatter, and content.
    
    Returns:
        Tuple of (section_name, frontmatter_dict, content_without_heading)
    """
    try:
        content = rule_path.read_text(encoding="utf-8")
    except Exception as e:
        logging.error(f"Failed to read {rule_path}: {e}")
        return "", {}, ""
    
    frontmatter, content_text = parse_frontmatter(content)
    
    # Extract section name from first # heading
    section_name = extract_section_name(content_text)
    
    # Remove the first # heading from content
    content_without_heading = re.sub(r"^#\s+.+$\n", "", content_text, count=1, flags=re.MULTILINE)
    content_without_heading = content_without_heading.strip()
    
    return section_name, frontmatter, content_without_heading


def collect_rules(rules_dir: Path) -> List[Tuple[str, str, Dict, str]]:
    """
    Collect all rules from .cursor/rules directory.
    
    Returns:
        List of tuples: (rule_folder_name, section_name, frontmatter, content)
    """
    rules: List[Tuple[str, str, Dict, str]] = []
    
    if not rules_dir.exists():
        logging.error(f"Rules directory not found: {rules_dir}")
        return rules
    
    for rule_folder in sorted(rules_dir.iterdir()):
        if not rule_folder.is_dir():
            continue
        
        rule_file = rule_folder / "RULE.md"
        if not rule_file.exists():
            logging.warning(f"RULE.md not found in {rule_folder}")
            continue
        
        section_name, frontmatter, content = read_rule_file(rule_file)
        if not section_name:
            logging.warning(f"No section name found in {rule_file}, using folder name")
            section_name = rule_folder.name.replace("-", " ").title()
        
        if content:
            rules.append((rule_folder.name, section_name, frontmatter, content))
        else:
            logging.warning(f"Empty content in {rule_file}")
    
    return rules


def bump_header_levels(content: str) -> str:
    """
    Increment every ATX-style markdown header by one level (# -> ##, ## -> ###, etc).
    Only matches unindented headers at the start of a line.
    """
    return re.sub(r"^(#{1,6})(\s)", r"#\1\2", content, flags=re.MULTILINE)


def format_frontmatter(frontmatter: Dict) -> str:
    """
    Format frontmatter dictionary as YAML string.
    
    Args:
        frontmatter: Dictionary of frontmatter metadata
    
    Returns:
        YAML-formatted string with --- delimiters
    """
    if not frontmatter:
        return ""
    
    if yaml is None:
        # Fallback: simple key-value format if PyYAML not available
        lines = ["---"]
        for key, value in sorted(frontmatter.items()):
            if isinstance(value, bool):
                lines.append(f"{key}: {str(value).lower()}")
            elif isinstance(value, str):
                lines.append(f'{key}: "{value}"')
            else:
                lines.append(f"{key}: {value}")
        lines.append("---")
        return "\n".join(lines)
    
    yaml_str = yaml.dump(frontmatter, default_flow_style=False, sort_keys=False)
    return f"---\n{yaml_str}---"


def generate_agents_md(rules: List[Tuple[str, str, Dict, str]], output_path: Path) -> None:
    """
    Generate AGENTS.md file from collected rules.
    
    Args:
        rules: List of (folder_name, section_name, frontmatter, content) tuples
        output_path: Path to write AGENTS.md
    """
    lines = ["# AGENTS.md", ""]
    
    for folder_name, section_name, frontmatter, content in rules:
        lines.append(f"## {section_name}")
        lines.append("")
        
        # Include frontmatter if present
        if frontmatter:
            frontmatter_str = format_frontmatter(frontmatter)
            lines.append(frontmatter_str)
            lines.append("")
        
        lines.append(bump_header_levels(content))
        lines.append("")
    
    output_path.write_text("\n".join(lines), encoding="utf-8")
    logging.info(f"Generated {output_path} with {len(rules)} sections")


def main() -> None:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate AGENTS.md from .cursor/rules directory"
    )
    parser.add_argument(
        "--rules-dir",
        type=Path,
        default=Path(".cursor/rules"),
        help="Path to rules directory (default: .cursor/rules)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("AGENTS.md"),
        help="Output file path (default: AGENTS.md, use - for stdout)",
    )
    
    args = parser.parse_args()
    
    rules = collect_rules(args.rules_dir)
    
    if not rules:
        logging.error("No rules found")
        return
    
    if args.output == Path("-"):
        # Write to stdout
        lines = ["# AGENTS.md", ""]
        for folder_name, section_name, frontmatter, content in rules:
            lines.append(f"## {section_name}")
            lines.append("")
            if frontmatter:
                frontmatter_str = format_frontmatter(frontmatter)
                lines.append(frontmatter_str)
                lines.append("")
            lines.append(bump_header_levels(content))
            lines.append("")
        sys.stdout.write("\n".join(lines))
    else:
        generate_agents_md(rules, args.output)


if __name__ == "__main__":
    setup_logging()
    main()

