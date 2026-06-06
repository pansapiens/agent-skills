---
name: analyse-protein-structure
description: "Analyze protein structures: PDB/CIF files, protein-protein/ligand interactions, FoldSeek/CATH similarity search"
compatibility: Requires python, curl, gunzip, and internet access for fetching structures and running scripts.
---

# Protein Structure Analysis

## When to Use This Skill

Use this skill whenever you need to work with protein 3D structures. Key triggers include:

- Analyzing protein structures in PDB or CIF format, or from a given PDB ID
- Investigating interactions between protein chains
- Studying protein-ligand binding interactions
- Finding structurally similar proteins (FoldSeek) and fold classification (CATH)
- Converting between PDB and CIF formats
- Creating visualizations of protein structures
- Extracting contact information (hydrogen bonds, hydrophobic contacts, ionic interactions, etc.)

## Workflow Phases

This skill provides a complete workflow for protein structure analysis:

1. **Fetch Structure** - Get PDB/CIF by ID or use local file
2. **Convert Format** - PDB ↔ CIF conversion using gemmi
3. **Run Analysis** - Analyze protein-protein or protein-ligand contacts with Arpeggio
4. **Visualize Results** - Generate images with pdb-images
5. **Search Similar** - Find similar proteins via FoldSeek/CATH

## Core Capabilities

### Structure Input

**Supported formats:**
- PDB files (`.pdb`, `.ent`) — auto-converted to mmCIF for Arpeggio
- mmCIF files (`.cif`, `.mmcif`)
- PDB IDs (use curl to fetch, then pass file path)

**Fetch structure (curl):**
```bash
# Asymmetric unit (single model)
curl -o 6LFO.cif "https://files.rcsb.org/download/6LFO.cif"

# Biological assembly (recommended for most analysis – multimer/quaternary structure)
curl -s "https://files.rcsb.org/download/6LFO.pdb1.gz" | gunzip -c >6LFO.biological_assembly.pdb
```
For most analysis (e.g. protein–protein interfaces, oligomeric state), use the **biological assembly** so the structure reflects the physiologically relevant multimer rather than the asymmetric unit.

### Contact Analysis with Arpeggio

The `arpeggio_contact_analyser.py` script wraps [pdbe-arpeggio](https://github.com/PDBeurope/arpeggio) — a library for calculating interatomic contacts.

> [!NOTE]
> `pdbe-arpeggio` depends on `openbabel` which requires system libraries. It **cannot** be used via `uv run` and must be installed in a `conda` environment. See [references/arpeggio.md](references/arpeggio.md) for installation and detailed usage instructions.

**Interaction types detected:**
- Hydrogen bonds (backbone and sidechain)
- Hydrophobic contacts
- Ionic / salt bridge interactions
- Aromatic π-π stacking (face-to-face, edge-to-face)
- Cation-π interactions
- Metal coordination
- Covalent bonds
- Donor-π interactions
- Amide-amide interactions

**Basic usage:**
```bash
python scripts/arpeggio_contact_analyser.py structure.cif
```

#### Selection Syntax

Arpeggio's `-s` / `--selection` flag uses this syntax (fields can be omitted):

```
/chain_id/residue_number[insertion_code]/atom_name
RESNAME:three_letter_code
```

**Examples:**
```bash
# Select a specific residue
-s /A/508/

# Select an entire chain
-s /A/

# Select a specific atom
-s /A/310/CA

# Select a ligand by residue name
-s RESNAME:HEM

# Multiple selections
-s /A/508/ RESNAME:HEM
```

When no selection is given, the entire structure is analysed.

#### Output Formats

```bash
# Native JSON output (default) — full arpeggio contact detail
python scripts/arpeggio_contact_analyser.py structure.cif -f json

# Tab-separated table
python scripts/arpeggio_contact_analyser.py structure.cif -f tsv

# Comma-separated table
python scripts/arpeggio_contact_analyser.py structure.cif -f csv -o contacts.csv
```

**TSV/CSV columns:** `type`, `bgn_chain`, `bgn_resname`, `bgn_resnum`, `bgn_atom`, `end_chain`, `end_resname`, `end_resnum`, `end_atom`, `distance`, `contact_types`, `interacting_entities`

#### Filtering Options

```bash
# Filter to contacts involving specific chains
--chains A,B

# Keep only inter-chain contacts (exclude intra-chain)
--interchain-only

# Combine: only A-B interface contacts
--chains A,B --interchain-only

# Distance cutoff (Ångströms, default: 5.0)
-i 4.0

# Include contacts between sequence-adjacent residues
--include-sequence-adjacent
```

Output goes to stdout by default. Use `-o file.json` to write to a file.

### Visualization

Generate images with multiple views and angles:
```bash
# Basic visualization
npx pdb-images structure.pdb --output-dir images/

# Multiple rotation angles
npx pdb-images structure.pdb --views front,side,top,bottom

# Different image types
npx pdb-images structure.pdb --types entry,assembly,ligand,domain

# AlphaFold predictions (pLDDT coloring)
npx pdb-images structure.cif --mode alphafold
```

**Image types:**
- `entry` - Overall structure overview
- `assembly` - Biological assembly
- `entity` - Chain-level visualization
- `ligand` - Ligand binding sites
- `domain` - Structural domains
- `modres` - Modified residues
- `bfactor` - B-factor coloring
- `validation` - Validation info
- `plddt` - AlphaFold confidence scores

- **Reference:** [references/pdb-images-usage.md](references/pdb-images-usage.md)

### ChimeraX Remote Control

Control a locally running ChimeraX instance via its REST API for advanced visualization, superimposition (`matchmaker`), interface selection, and custom coloring presets.

- **Reference:** [references/chimerax.md](references/chimerax.md)

### PyMOL Remote Control

Control a locally running PyMOL instance via its XML-RPC server for visualization, selection logic, superimposition, and custom coloring presets. You can also use the `pymol_xmlrpc_command.py` script to run commands programmatically.

- **Reference:** [references/pymol.md](references/pymol.md)

### Structural Similarity Search

**FoldSeek API integration:**
```bash
# Search against CATH database
uv run scripts/foldseek_search.py --structure-file query.pdb --cath-only --top-hits 10

# Search multiple databases
uv run scripts/foldseek_search.py --structure-file query.pdb \
  --databases cath50,afdb50,pdb100

# Search by PDB ID (auto-fetches)
uv run scripts/foldseek_search.py --pdb-id 1ABC --databases cath50
```

**Supported databases:**
- `cath50` - CATH structural classification (recommended)
- `afdb50` - AlphaFold DB (50% clustered)
- `pdb100` - All PDB structures
- `afdb-swissprot` - SwissProt AlphaFold predictions

**Result interpretation:**
- TM-score > 0.5 indicates similar fold
- CATH superfamily provides functional classification
- Topology and homologous superfamily levels

## Common Workflows

### Workflow 1: Analyse All Contacts in a Structure

Goal: Get a complete contact map of all interactions.

```bash
# Fetch structure
curl -o data/1tqn.cif "https://files.rcsb.org/download/1TQN.cif"

# All contacts, JSON output
python scripts/arpeggio_contact_analyser.py data/1tqn.cif -o results/1tqn_contacts.json

# All contacts, tabular output
python scripts/arpeggio_contact_analyser.py data/1tqn.cif -f tsv -o results/1tqn_contacts.tsv
```

### Workflow 2: Analyse Protein-Protein Interface

Goal: Understand interactions between two protein chains in a dimer or complex.

```bash
# Fetch biological assembly
curl -s "https://files.rcsb.org/download/1A2B.cif" -o data/1a2b.cif

# Inter-chain contacts between chains A and B only
python scripts/arpeggio_contact_analyser.py data/1a2b.cif \
  --chains A,B --interchain-only \
  -f tsv -o results/1a2b_AB_interface.tsv

# Or use selection to focus arpeggio on chain A, then filter
python scripts/arpeggio_contact_analyser.py data/1a2b.cif \
  -s /A/ --interchain-only \
  -f tsv -o results/1a2b_A_interface.tsv
```

**What to look for in the output:**
- Hydrogen bonds at the interface
- Hydrophobic patches
- Salt bridges (ionic contacts)
- Key binding residues

### Workflow 3: Analyse Contacts Within a Domain

Goal: Find contacts within a specific region of a chain (e.g. residues 100-200 of chain A).

```bash
# Use arpeggio selection for a specific residue range
# Run full analysis, then filter the tabular output
python scripts/arpeggio_contact_analyser.py data/structure.cif \
  -s /A/ -f tsv | awk -F'\t' '$4 >= 100 && $4 <= 200'
```

Alternatively, use a selection for a specific binding site residue:
```bash
python scripts/arpeggio_contact_analyser.py data/structure.cif \
  -s /A/508/ -f tsv -o results/binding_site_508.tsv
```

### Workflow 4: Identify Ligand Binding Site

Goal: Find which protein residues interact with a ligand.

```bash
# Analyse contacts for a specific ligand (e.g. HEM heme group)
python scripts/arpeggio_contact_analyser.py data/1tqn.cif \
  -s RESNAME:HEM -f tsv -o results/hem_contacts.tsv

# Multiple ligands
python scripts/arpeggio_contact_analyser.py data/complex.cif \
  -s RESNAME:HEM RESNAME:NAG \
  -f json -o results/ligand_contacts.json

# Tighter distance cutoff for close contacts only
python scripts/arpeggio_contact_analyser.py data/complex.cif \
  -s RESNAME:ATP -i 4.0 \
  -f tsv -o results/atp_binding.tsv
```

**What to look for:**
- Residues within 4Å of ligand
- Hydrogen bond donors/acceptors
- Hydrophobic environment
- Metal coordination (if applicable)

### Workflow 5: All Inter-Chain Contacts

Goal: Find all contacts between any different chains in a multi-chain complex.

```bash
python scripts/arpeggio_contact_analyser.py data/complex.cif \
  --interchain-only -f tsv -o results/all_interfaces.tsv
```

### Workflow 6: Find Functionally Similar Proteins

Goal: Identify proteins with similar folds and potential functional relationships.

```bash
# Search for similar structures
uv run scripts/foldseek_search.py \
  --structure-file query.pdb \
  --cath-only \
  --top-hits 20 \
  --output-dir results/

# Review results in results/foldseek_results.tsv
# Look for: High TM-score, matching CATH superfamily
```

**What to look for:**
- TM-score > 0.7 indicates strong similarity
- Same CATH superfamily = related function
- Different CATH = convergent evolution
- Sequence vs structural similarity differences

### Workflow 7: Format Conversion Pipeline

Goal: Convert between PDB and CIF formats for different tools.

```bash
# PDB → CIF
uv run scripts/format_converter.py \
  --input-file structure.pdb \
  --output-file structure.cif \
  --input-format pdb \
  --output-format cif

# CIF → PDB
uv run scripts/format_converter.py \
  --input-file structure.cif \
  --output-file structure.pdb \
  --input-format cif \
  --output-format pdb
```

**Note:** PDB files given to `arpeggio_contact_analyser.py` are auto-converted to mmCIF internally, so explicit conversion is only needed for other tools.

### Workflow 8: Complete Analysis Pipeline

Goal: Comprehensive analysis of a protein structure.

```bash
# 1. Fetch structure
curl -o data/7rsa.cif "https://files.rcsb.org/download/7rsa.cif"

# 2. Analyse inter-chain contacts
python scripts/arpeggio_contact_analyser.py data/7rsa.cif \
  --interchain-only -f tsv -o results/7rsa_interfaces.tsv

# 3. Analyse ligand contacts (if present)
python scripts/arpeggio_contact_analyser.py data/7rsa.cif \
  -s RESNAME:SO4 -f tsv -o results/7rsa_ligand.tsv

# 4. Search similar structures
uv run scripts/foldseek_search.py \
  --structure-file data/7rsa.cif \
  --cath-only \
  --top-hits 10 \
  --output-dir results/foldseek/

# 5. Generate visualizations
npx pdb-images data/7rsa.cif \
  --output-dir results/images/ \
  --types entry,ligand,assembly \
  --views front,side,top
```

## Running Scripts

All Python scripts in this skill use PEP 722 inline script metadata and **must** be run with `uv run` from the skill root (the `analyse-protein-structure/` directory). Do not run them with plain `python` or without being in the skill root.

```bash
# From the skill root (analyse-protein-structure/)
curl -o data/1abc.cif "https://files.rcsb.org/download/1ABC.cif"
python scripts/arpeggio_contact_analyser.py data/1abc.cif --chains A,B --interchain-only -f tsv
```

## File Structure

```
analyse-protein-structure/
├── SKILL.md
├── scripts/
│   ├── constants.py                       # Shared constants
│   ├── format_converter.py                # PDB ↔ CIF conversion
│   ├── arpeggio_contact_analyser.py       # Contact analysis (wraps pdbe-arpeggio)
│   ├── foldseek_search.py                 # FoldSeek API
│   ├── run_foldseek_api.py                # FoldSeek API client
│   ├── rcsb_data_api.py                   # Data API GraphQL
│   ├── rcsb_search_api.py                 # Search API
│   ├── rcsb_sequence_coordinates_api.py   # Sequence Coordinates GraphQL
│   ├── rcsb_alignment_api.py              # Structure alignment submit/poll
│   └── pymol_xmlrpc_command.py            # PyMOL remote control
└── references/
    ├── arpeggio.md                        # pdbe-arpeggio reference
    ├── pdb-images-usage.md                # Visualization guide
    ├── rcsb-data-api.md                   # Data API usage
    ├── rcsb-search-api.md                 # Search API usage
    ├── rcsb-sequence-coordinates-api.md   # Sequence Coordinates API
    ├── rcsb-alignment-api.md              # Alignment API usage
    ├── chimerax.md                        # ChimeraX usage and remote control
    └── pymol.md                           # PyMOL usage and remote control
```

## Dependencies

Each script declares its own dependencies via PEP 722 headers; `uv run` installs them on first use. Key packages:

- `biopython` - Structure parsing
- `gemmi` - Format conversion and CIF handling
- `pandas` - Tabular output for contacts
- `numpy` - Numerical operations
- `requests` - API calls
- `openbabel` - Required by pdbe-arpeggio for hydrogen handling
- `pdbe-arpeggio` - Interatomic contact calculation

### External Tools
- **pdb-images** - Visualization via npm (`npm install -g pdb-images`)

## Troubleshooting

### PDB Fetching Issues
- **Invalid PDB ID**: Check ID at https://www.rcsb.org/
- **Network timeout**: Retry after a few seconds
- **404 error**: PDB ID may be obsolete or removed

### Conversion Errors
- **Multi-model NMR**: First model used, specify if needed
- **Missing atoms**: Check file integrity
- **Alternate locations**: Use altloc A or specify

### Contact Analysis
- **Empty results**: Check distance cutoff, chain/selection specification
- **PDB format**: arpeggio_contact_analyser.py auto-converts PDB to mmCIF, but some PDB quirks may cause issues — use mmCIF when possible
- **openbabel errors**: Ensure openbabel is installed (`conda install -c conda-forge openbabel`)

### FoldSeek API
- **Rate limiting**: Wait 10-30 seconds between requests
- **No hits**: Try less restrictive parameters or different database
- **Timeout**: FoldSeek API may be busy, retry later

### Visualization
- **npm not found**: Install Node.js from https://nodejs.org/
- **Large files**: May take time, be patient
- **No images**: Check PDB file format and structure validity

## Advanced Features

### Batch Processing
Process multiple PDB IDs in sequence (fetch with curl, then analyse):
```bash
for pdb_id in 6LFO 6LFM; do
  curl -s "https://files.rcsb.org/download/${pdb_id}.cif" -o "data/${pdb_id}.cif"
  python scripts/arpeggio_contact_analyser.py "data/${pdb_id}.cif" \
    --interchain-only -f tsv -o "results/${pdb_id}_interfaces.tsv"
done
```

### Custom Interaction Filters
Filter tabular results by interaction type:
```bash
# Keep only hydrogen bonds and ionic contacts from TSV output
python scripts/arpeggio_contact_analyser.py data/structure.cif -f tsv \
  | awk -F'\t' 'NR==1 || $11 ~ /hbond|ionic/'
```

Or with Python:
```python
import pandas as pd
df = pd.read_csv('contacts.tsv', sep='\t')
hbonds = df[df['contact_types'].str.contains('hbond', na=False)]
```

### AlphaFold Predictions
Fetch AlphaFold structure by UniProt ID:
```bash
# AlphaFold files are mmCIF — use directly
curl -o data/AF_P00533.cif \
  "https://alphafold.ebi.ac.uk/files/AF-P00533-F1-model_v4.cif"

python scripts/arpeggio_contact_analyser.py data/AF_P00533.cif \
  -f tsv -o results/af_contacts.tsv
```

## Sub-skills: RCSB PDB Web APIs

Use these when you need to query or align PDB data programmatically beyond fetching coordinate files (which this skill already covers with `curl` and files.rcsb.org).

### Data API

- **When:** Need metadata or annotations for a known PDB ID or CSM ID (title, experimental method, entities, assemblies, sequences, citations, chemical components, etc.).
- **Capabilities:** REST and GraphQL; entry, polymer_entity, assembly, polymer_entity_instance, chemical components.
- **Reference:** [references/rcsb-data-api.md](references/rcsb-data-api.md)

### Search API

- **When:** Need to *find* PDB IDs (or entity/assembly/instance IDs) by text, sequence, structure similarity, or chemical.
- **Capabilities:** Text/attribute search, sequence search (MMseqs2), structure/embedding search, chemical similarity, faceting, grouping.
- **Reference:** [references/rcsb-search-api.md](references/rcsb-search-api.md)

### Sequence Coordinates API

- **When:** Need alignments between PDB/UniProt/RefSeq or positional features (domains, sites, secondary structure) on a sequence.
- **Capabilities:** GraphQL; alignment query (e.g. UniProt–PDB entity, genome–PDB); annotations from UniProt, CATH, SCOPe, etc.
- **Reference:** [references/rcsb-sequence-coordinates-api.md](references/rcsb-sequence-coordinates-api.md)

### Alignment API

- **When:** Need pairwise (or list) structure alignment (superimposition), RMSD, TM-score, or sequence alignment derived from 3D superposition.
- **Capabilities:** Submit job (GET/POST), poll by ticket; rigid (e.g. jFATCAT-rigid, jCE, TM-align) and flexible (jFATCAT-flexible, jCE-CP).
- **Reference:** [references/rcsb-alignment-api.md](references/rcsb-alignment-api.md)

## References

- **Arpeggio**: https://github.com/PDBeurope/arpeggio
- **FoldSeek**: https://foldseek.steineggerlab.de/
- **CATH**: https://www.cathdb.info/
- **Gemmi**: https://github.com/project-gemmi/gemmi
- **PDB Images**: https://github.com/PDBeurope/pdb-images
- **BioPython**: https://biopython.org/
- **RCSB PDB**: https://www.rcsb.org/
