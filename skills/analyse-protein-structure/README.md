# Protein Structure Analysis

Analyze protein structures in PDB/mmCIF format with contact detection, structural similarity searches, and visualization capabilities.

## Quick Start

### Fetch and Analyse a Structure

```bash
# 1. Fetch a structure (mmCIF preferred for arpeggio)
curl -o data/7rsa.cif "https://files.rcsb.org/download/7RSA.cif"

# 2. Analyse all contacts (JSON output to stdout)
python scripts/arpeggio_contact_analyser.py data/7rsa.cif

# 3. Analyse inter-chain interface as TSV
python scripts/arpeggio_contact_analyser.py data/7rsa.cif \
  --chains A,B --interchain-only \
  -f tsv -o results/7rsa_interface.tsv

# 4. Analyse ligand contacts
python scripts/arpeggio_contact_analyser.py data/7rsa.cif \
  -s RESNAME:SO4 -f tsv -o results/7rsa_ligand.tsv
```

### Search for Similar Structures

```bash
uv run scripts/foldseek_search.py \
  --structure-file data/query.pdb \
  --cath-only \
  --top-hits 10
```

### Convert Between Formats

```bash
# PDB → CIF
uv run scripts/format_converter.py \
  --input-file structure.pdb \
  --output-file structure.cif

# CIF → PDB
uv run scripts/format_converter.py \
  --input-file structure.cif \
  --output-file structure.pdb
```

## Core Features

- **Contact Analysis**: pdbe-arpeggio wrapper with JSON/TSV/CSV output
- **Interaction Types**: Hydrogen bonds, hydrophobic, ionic, aromatic, metal, covalent, cation-π
- **Protein-Protein**: Analyse interfaces between chains (`--chains`, `--interchain-only`)
- **Protein-Ligand**: Identify binding site residues (`-s RESNAME:HEM`)
- **Structural Search**: FoldSeek API with CATH database
- **Format Conversion**: PDB ↔ CIF using gemmi
- **Visualization**: pdb-images with multiple views

## Scripts

- `arpeggio_contact_analyser.py` — Contact analysis (wraps pdbe-arpeggio)
- `format_converter.py` — PDB ↔ CIF conversion
- `foldseek_search.py` — FoldSeek structural search
- `pymol_xmlrpc_command.py` — PyMOL remote control

## Documentation

See [SKILL.md](SKILL.md) for detailed documentation including:
- Selection syntax and workflow examples
- Output format details
- Common use cases
- Troubleshooting guide

See [references/pdb-images-usage.md](references/pdb-images-usage.md) for visualization guide.

## Examples

### Ligand Binding Site

```bash
python scripts/arpeggio_contact_analyser.py complex.cif \
  -s RESNAME:HEM -i 4.0 -f tsv -o results/hem_contacts.tsv
```

### Complete Analysis Pipeline

```bash
# 1. Fetch structure
curl -o data/1abc.cif "https://files.rcsb.org/download/1ABC.cif"

# 2. Analyse inter-chain contacts
python scripts/arpeggio_contact_analyser.py data/1abc.cif \
  --chains A,B --interchain-only \
  -f tsv -o results/1abc_interface.tsv

# 3. Find similar structures
uv run scripts/foldseek_search.py \
  --structure-file data/1abc.cif \
  --cath-only \
  --top-hits 20 \
  --output-dir results/

# 4. Generate visualizations
npx pdb-images data/1abc.cif \
  --output-dir results/images/ \
  --views front,side,top \
  --types entry,ligand,domain
```

## Requirements

- Python 3.9+
- pdbe-arpeggio + openbabel (requires a conda environment, see `references/arpeggio.md` for installation instructions)
- gemmi (for format conversion)
- Node.js/npm (for pdb-images visualization)

## License

See project license file.
