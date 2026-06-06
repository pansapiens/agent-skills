#!/usr/bin/env python
"""Convert between PDB and CIF formats using gemmi."""

# /// script
# requires-python = ">=3.9"
# dependencies = [
#   "biopython>=1.83",
#   "gemmi>=0.6.4",
#   "pandas>=2.0.0",
#   "numpy>=2.0.0",
#   "requests>=2.31.0",
#   "rich>=13.0.0",
# ]
# ///

import argparse
import logging
from pathlib import Path

import gemmi

PDB_EXTENSIONS = [".pdb", ".ent", "pdb1"]
CIF_EXTENSIONS = [".cif", ".mmcif"]


def _detect_format(file_path: Path) -> str:
    suffix = file_path.suffix.lower()
    if suffix in PDB_EXTENSIONS:
        return "pdb"
    if suffix in CIF_EXTENSIONS:
        return "cif"
    raise ValueError(f"Unknown file format: {suffix}")

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def convert_with_gemmi(input_file: Path, output_file: Path, input_format: str, output_format: str) -> bool:
    """Convert structure file using gemmi Python API."""
    try:
        logger.info(f"Reading {input_file}")
        structure = gemmi.read_structure(str(input_file))
        out_path = str(output_file)
        if output_format == "pdb":
            structure.write_pdb(out_path)
        else:
            structure.make_mmcif_document().write_file(out_path)
        logger.info(f"Successfully converted {input_file} to {output_file}")
        return True
    except (RuntimeError, OSError) as e:
        logger.error(f"Conversion failed: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Convert between PDB and CIF formats using gemmi")
    parser.add_argument("--input-file", required=True, type=Path, help="Input structure file")
    parser.add_argument("--output-file", required=True, type=Path, help="Output structure file")
    parser.add_argument("--input-format", help="Input format (auto-detected if not specified)")
    parser.add_argument("--output-format", help="Output format (auto-detected if not specified)")
    
    args = parser.parse_args()
    
    if not args.input_file.exists():
        logger.error(f"Input file does not exist: {args.input_file}")
        return 1
    
    if not args.input_format:
        args.input_format = _detect_format(args.input_file)
        logger.info(f"Detected input format: {args.input_format}")
    
    if not args.output_format:
        if args.output_file.suffix.lower() in PDB_EXTENSIONS:
            args.output_format = "pdb"
        elif args.output_file.suffix.lower() in CIF_EXTENSIONS:
            args.output_format = "cif"
        else:
            logger.error(f"Could not detect output format from: {args.output_file}")
            return 1
        logger.info(f"Detected output format: {args.output_format}")
    
    if args.input_format == args.output_format:
        logger.error(f"Input and output formats are the same: {args.input_format}")
        return 1
    
    success = convert_with_gemmi(args.input_file, args.output_file, args.input_format, args.output_format)
    
    return 0 if success else 1


if __name__ == "__main__":
    exit(main())
