#!/usr/bin/env python
"""Wrapper around pdbe-arpeggio for protein contact analysis.

pdbe-arpeggio requires openbabel which needs conda, so this script
cannot be run via `uv run`. See references/arpeggio.md for installation.

Usage: python scripts/arpeggio_contact_analyser.py structure.cif [options]
"""

from typing import Optional, List, Dict, Any, TYPE_CHECKING
import io
import sys
import argparse
import json
import logging
import tempfile
from pathlib import Path

if TYPE_CHECKING:
    import pandas as pd

logger = logging.getLogger(__name__)

PDB_EXTENSIONS = {".pdb", ".ent"}
CIF_EXTENSIONS = {".cif", ".mmcif"}


def convert_pdb_to_cif(pdb_path: Path) -> Path:
    """Convert PDB to mmCIF using gemmi, returning path to temp CIF file."""
    import gemmi

    structure = gemmi.read_structure(str(pdb_path))
    cif_path = Path(tempfile.mktemp(suffix=".cif"))
    structure.make_mmcif_document().write_file(str(cif_path))
    logger.info("Converted %s -> %s", pdb_path.name, cif_path.name)
    return cif_path


def run_arpeggio(
    cif_path: Path,
    selection: Optional[List[str]] = None,
    interacting_cutoff: float = 5.0,
    vdw_comp: float = 0.1,
    include_sequence_adjacent: bool = False,
) -> List[Dict[str, Any]]:
    """Run pdbe-arpeggio on a mmCIF file and return the contacts list."""
    from arpeggio.core import InteractionComplex

    ic = InteractionComplex(str(cif_path), vdw_comp, interacting_cutoff)
    ic.structure_checks()
    ic.address_ambiguities()
    ic.initialize()
    ic.run_arpeggio(
        selection or [],
        interacting_cutoff,
        vdw_comp,
        include_sequence_adjacent,
    )
    return ic.get_contacts()


def filter_by_chains(
    contacts: List[Dict], chains: List[str], interchain_only: bool = False
) -> List[Dict]:
    """Filter contacts to those involving specified chains."""
    chain_set = set(chains)
    filtered = []
    for c in contacts:
        bgn_chain = c.get("bgn", {}).get("auth_asym_id")
        end_chain = c.get("end", {}).get("auth_asym_id")
        if bgn_chain not in chain_set and end_chain not in chain_set:
            continue
        if interchain_only and bgn_chain == end_chain:
            continue
        filtered.append(c)
    return filtered


def filter_interchain_only(contacts: List[Dict]) -> List[Dict]:
    """Keep only contacts between different chains."""
    return [
        c for c in contacts
        if c.get("bgn", {}).get("auth_asym_id") != c.get("end", {}).get("auth_asym_id")
    ]


def contacts_to_table(contacts: List[Dict]) -> "pd.DataFrame":
    """Flatten arpeggio contacts into a tabular DataFrame."""
    import pandas as pd

    rows = []
    for c in contacts:
        bgn = c.get("bgn", {})
        end = c.get("end", {})
        rows.append({
            "type": c.get("type", ""),
            "bgn_chain": bgn.get("auth_asym_id", ""),
            "bgn_resname": bgn.get("label_comp_id", ""),
            "bgn_resnum": bgn.get("auth_seq_id", ""),
            "bgn_atom": bgn.get("auth_atom_id", ""),
            "end_chain": end.get("auth_asym_id", ""),
            "end_resname": end.get("label_comp_id", ""),
            "end_resnum": end.get("auth_seq_id", ""),
            "end_atom": end.get("auth_atom_id", ""),
            "distance": c.get("distance", ""),
            "contact_types": ";".join(c.get("contact", [])),
            "interacting_entities": c.get("interacting_entities", ""),
        })
    return pd.DataFrame(rows)


def write_output(
    contacts: List[Dict],
    fmt: str,
    output_path: Optional[Path],
) -> None:
    """Write contacts in the requested format to file or stdout."""
    if output_path and str(output_path) != "-":
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fh = open(output_path, "w")
    else:
        fh = sys.stdout

    try:
        if fmt == "json":
            json.dump(contacts, fh, indent=2, sort_keys=True)
            fh.write("\n")
        elif fmt in ("tsv", "csv"):
            df = contacts_to_table(contacts)
            sep = "\t" if fmt == "tsv" else ","
            df.to_csv(fh, sep=sep, index=False)
    finally:
        if fh is not sys.stdout:
            fh.close()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Analyse protein contacts using pdbe-arpeggio.",
        epilog=(
            "Selection syntax (passed to arpeggio):\n"
            "  /chain/resnum/atom   e.g. /A/508/  /A/310/CA\n"
            "  RESNAME:code         e.g. RESNAME:HEM\n"
            "Multiple selections can be given: -s /A/ /B/\n"
            "If no selection is given, the entire structure is analysed."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "structure_file", type=Path,
        help="PDB or mmCIF structure file (PDB auto-converted to mmCIF)",
    )
    parser.add_argument(
        "-s", "--selection", nargs="+",
        help="Arpeggio selection(s), e.g. /A/508/ or RESNAME:HEM",
    )
    parser.add_argument(
        "--chains",
        help="Filter output to contacts involving these chains (comma-separated, e.g. A,B)",
    )
    parser.add_argument(
        "--interchain-only", action="store_true",
        help="Keep only inter-chain contacts (exclude intra-chain)",
    )
    parser.add_argument(
        "-f", "--format", default="json", choices=["json", "tsv", "csv"],
        help="Output format (default: json)",
    )
    parser.add_argument(
        "-o", "--output", type=Path, default=None,
        help="Output file path (default: stdout, use - for stdout)",
    )
    parser.add_argument(
        "-i", "--interacting", type=float, default=5.0,
        help="Distance cutoff in Å (default: 5.0)",
    )
    parser.add_argument(
        "--vdw-comp", type=float, default=0.1,
        help="VdW compensation factor (default: 0.1)",
    )
    parser.add_argument(
        "--include-sequence-adjacent", action="store_true",
        help="Include contacts between sequence-adjacent residues",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO, format="%(levelname)s: %(message)s", stream=sys.stderr
    )

    if not args.structure_file.exists():
        logger.error("Structure file not found: %s", args.structure_file)
        return 1

    # Auto-convert PDB to mmCIF if needed
    suffix = args.structure_file.suffix.lower()
    tmp_cif = None
    if suffix in PDB_EXTENSIONS:
        logger.info("PDB detected — converting to mmCIF for arpeggio")
        tmp_cif = convert_pdb_to_cif(args.structure_file)
        cif_path = tmp_cif
    elif suffix in CIF_EXTENSIONS:
        cif_path = args.structure_file
    else:
        logger.error("Unsupported file format: %s (use .pdb or .cif)", suffix)
        return 1

    try:
        contacts = run_arpeggio(
            cif_path,
            selection=args.selection,
            interacting_cutoff=args.interacting,
            vdw_comp=args.vdw_comp,
            include_sequence_adjacent=args.include_sequence_adjacent,
        )
    except Exception as e:
        logger.error("Arpeggio analysis failed: %s", e)
        return 1
    finally:
        if tmp_cif and tmp_cif.exists():
            tmp_cif.unlink()

    if not contacts:
        logger.warning("No contacts found")
        return 0

    logger.info("Found %d contacts", len(contacts))

    if args.chains:
        chain_list = [c.strip() for c in args.chains.split(",")]
        contacts = filter_by_chains(contacts, chain_list, args.interchain_only)
        logger.info("After chain filter: %d contacts", len(contacts))
    elif args.interchain_only:
        contacts = filter_interchain_only(contacts)
        logger.info("After interchain filter: %d contacts", len(contacts))

    write_output(contacts, args.format, args.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
