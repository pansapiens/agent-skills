# pdbe-arpeggio Reference

[pdbe-arpeggio](https://github.com/PDBeurope/arpeggio) calculates interatomic contacts in protein structures based on the rules defined in [CREDO](https://pubmed.ncbi.nlm.nih.gov/19207418/).

## Installation

pdbe-arpeggio requires openbabel which needs system libraries, so it must be installed via conda (not pip/uv alone).

```bash
# Create a dedicated conda environment
conda create -y -n arpeggio -c conda-forge python=3.9 gemmi openbabel biopython numpy pandas
conda activate arpeggio

# Install pdbe-arpeggio into the conda env
pip install --no-cache-dir pdbe-arpeggio
```

If using an existing conda environment, install the dependencies first:
```bash
conda install -y -c conda-forge gemmi openbabel biopython numpy pandas -y
pip install --no-cache-dir pdbe-arpeggio
```

Verify installation:
```bash
conda activate arpeggio
python -c "from arpeggio.core import InteractionComplex; print('OK')"
```

## Running the Wrapper Script

The wrapper script `scripts/arpeggio_contact_analyser.py` must be run with the conda environment active (not via `uv run`):

```bash
conda activate arpeggio
python scripts/arpeggio_contact_analyser.py structure.cif [options]
```

## Input Format

pdbe-arpeggio **only supports mmCIF format**. The wrapper script auto-converts PDB files to mmCIF using gemmi, but using mmCIF directly is preferred. Fetch mmCIF from the PDB:

```bash
curl -o structure.cif "https://files.rcsb.org/download/1TQN.cif"
```

## Selection Syntax

Arpeggio's `-s` / `--selection` flag tells arpeggio which atoms to use as the query. The syntax is:

```
/<chain_id>/<residue_number>[<insertion_code>]/<atom_name>
RESNAME:<three_letter_code>
```

Fields can be omitted. Examples:

| Selection | Meaning |
|-----------|---------|
| `/A/` | All atoms in chain A |
| `/A/508/` | All atoms in residue 508 of chain A |
| `/A/310/CA` | Only the CA atom of residue 310, chain A |
| `RESNAME:HEM` | All atoms in HEM (heme) residues |
| `-s /A/ /B/` | Multiple selections (chain A and chain B) |

When no selection is given, the entire structure is analysed.

## Contact Types

### atom-atom interactions
Standard interatomic contacts: `proximal`, `hbond`, `weak_hbond`, `polar`, `weak_polar`, `hydrophobic`, `ionic`, `metal_complex`, `xbond`, `carbonyl`, `vdw_clash`, `vdw`.

### atom-plane interactions
Cation-π and donor-π interactions: `CARBONPI`, `CATIONPI`, `DONORPI`, `HALOGENPI`, `METSULPHURPI`.

### plane-plane interactions
Aromatic stacking using [Chakrabarti and Bhattacharyya (2007)](https://doi.org/10.1016/j.pbiomolbio.2007.03.016) nomenclature: `FT` (face-to-face), `ET` (edge-to-face), `OF` (offset face-to-face), `EF` (edge-to-face).

### group-group interactions
Amide-amide (`AMIDEAMIDE`), amide-ring (`AMIDERING`).

## JSON Output Format

Each contact is a dict with these keys:

```json
{
    "bgn": {
        "auth_asym_id": "A",
        "auth_atom_id": "CB",
        "auth_seq_id": 313,
        "label_comp_id": "VAL",
        "label_comp_type": "P",
        "pdbx_PDB_ins_code": " "
    },
    "contact": ["proximal", "hydrophobic"],
    "distance": 4.02,
    "end": {
        "auth_asym_id": "A",
        "auth_atom_id": "CBB",
        "auth_seq_id": 508,
        "label_comp_id": "HEM",
        "label_comp_type": "B",
        "pdbx_PDB_ins_code": " "
    },
    "interacting_entities": "INTER",
    "type": "atom-atom"
}
```

**Key fields:**
- `bgn`/`end` — the two interacting atoms/planes/groups
- `auth_asym_id` — chain ID
- `auth_seq_id` — residue number
- `label_comp_id` — residue name (e.g. VAL, HEM)
- `label_comp_type` — `P` (polymer/protein), `B` (bound molecule/ligand), `W` (water)
- `contact` — list of detected interaction types
- `distance` — distance in Ångströms
- `interacting_entities` — `INTER` (between different entities), `INTRA_SELECTION`, `INTRA_NON_SELECTION`, `INTRA_BINDING_SITE`, `SELECTION_WATER`, `NON_SELECTION_WATER`
- `type` — `atom-atom`, `atom-plane`, `plane-plane`, `group-group`

## Tabular Output (TSV/CSV)

The wrapper's `-f tsv` or `-f csv` mode flattens each contact to a row:

| Column | Description |
|--------|-------------|
| `type` | Contact type (atom-atom, atom-plane, etc.) |
| `bgn_chain` | Beginning atom chain ID |
| `bgn_resname` | Beginning residue name |
| `bgn_resnum` | Beginning residue number |
| `bgn_atom` | Beginning atom name |
| `end_chain` | End atom chain ID |
| `end_resname` | End residue name |
| `end_resnum` | End residue number |
| `end_atom` | End atom name |
| `distance` | Distance in Å |
| `contact_types` | Semicolon-separated interaction types |
| `interacting_entities` | Entity relationship |

## Python API

For programmatic use, the wrapper functions can be imported:

```python
from arpeggio_contact_analyser import run_arpeggio, filter_by_chains, contacts_to_table

contacts = run_arpeggio(Path("structure.cif"), selection=["/A/"])
interface = filter_by_chains(contacts, ["A", "B"], interchain_only=True)
df = contacts_to_table(interface)
```

## CLI Options Reference

```
python scripts/arpeggio_contact_analyser.py STRUCTURE_FILE [options]

positional arguments:
  structure_file        PDB or mmCIF structure file (PDB auto-converted)

options:
  -s, --selection       Arpeggio selection(s), e.g. /A/508/ or RESNAME:HEM
  --chains CHAINS       Filter to contacts involving these chains (e.g. A,B)
  --interchain-only     Keep only inter-chain contacts
  -f, --format          json (default), tsv, or csv
  -o, --output FILE     Output file (default: stdout)
  -i, --interacting N   Distance cutoff in Å (default: 5.0)
  --vdw-comp N          VdW compensation factor (default: 0.1)
  --include-sequence-adjacent
                        Include contacts between sequence-adjacent residues
```

## Citation

Harry C Jubb, Alicia P Higueruelo, Bernardo Ochoa-Montaño, Will R Pitt, David B Ascher, Tom L Blundell, [Arpeggio: A Web Server for Calculating and Visualising Interatomic Interactions in Protein Structures](https://doi.org/10.1016/j.jmb.2016.12.004). Journal of Molecular Biology, Volume 429, Issue 3, 2017, Pages 365-371.
