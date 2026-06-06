# Gemmi – PDB/CIF Manipulation and Analysis

Gemmi is a library and command-line toolkit for working with macromolecular structure files (PDB, mmCIF, mmJSON). It can be used as a Python library (`pip install gemmi`) or as a standalone CLI program (`pip install gemmi-program`, or `uvx --from gemmi-program gemmi`).

- **Docs:** https://gemmi.readthedocs.io/en/latest/
- **CLI program docs:** https://gemmi.readthedocs.io/en/latest/program.html
- **Python API:** https://gemmi.readthedocs.io/en/latest/analysis.html
- **GitHub:** https://github.com/project-gemmi/gemmi

## Installation

```bash
# Python library
pip install gemmi

# CLI program (standalone)
pip install gemmi-program

# Run directly without installing
uvx --from gemmi-program gemmi
```

## CLI: gemmi convert

Convert between PDB, mmCIF and mmJSON formats. Also provides structure manipulation options.

```bash
# CIF → PDB
gemmi convert input.cif output.pdb

# PDB → CIF
gemmi convert input.pdb output.cif

# Rename chains during conversion
gemmi convert --rename-chain=A:X --rename-chain=B:Y input.cif output.pdb

# Add missing chain IDs
gemmi convert --rename-chain=:A input.pdb output.pdb

# Shorten long chain names (useful for PDB format limits)
gemmi convert --shorten input.cif output.pdb

# Extract a selection
gemmi convert --select='//A/10-50' input.cif output.cif

# Remove a selection
gemmi convert --remove='(HOH)' input.cif output.cif

# Remove hydrogens / waters / ligands+waters
gemmi convert --remove-h input.pdb output.pdb
gemmi convert --remove-waters input.pdb output.pdb
gemmi convert --remove-lig-wat input.pdb output.pdb

# Expand biological assembly
gemmi convert --assembly=1 input.cif output.pdb

# Expand strict NCS
gemmi convert --expand-ncs=x input.cif output.pdb

# Trim amino acids to alanine (poly-Ala model)
gemmi convert --trim-to-ala input.pdb output.pdb

# Set or constrain B-factors
gemmi convert -B 20 input.pdb output.pdb        # set all to 20
gemmi convert -B 5:100 input.pdb output.pdb     # clamp to range

# Apply symmetry operation
gemmi convert --apply-symop='-x,y+1/2,-z' input.cif output.cif

# Write to stdout (PDB format by default)
gemmi convert input.cif -
```

Key options:
- `--from=FORMAT` / `--to=FORMAT` – override auto-detection (`mmcif`, `pdb`, `mmjson`)
- `--rename-chain=OLD:NEW` – rename chain OLD to NEW (repeatable)
- `--select=SEL` / `--remove=SEL` – atom selection using CID (MMDB) syntax
- `--assembly=ID` – output biological assembly
- `--expand-ncs=dup|num|x` – expand strict NCS
- `--minimal` – write only essential records
- `--shorten` – shorten chain names to 1-2 characters

## CLI: gemmi grep

Search for tag values in CIF/mmCIF files. Much faster and more robust than text-based grep for CIF data.

```bash
# Get R-free factor
gemmi grep _refine.ls_R_factor_R_free 5fyi.cif.gz

# Search with globbing
gemmi grep -t '_*free' 3gem.cif

# Get resolution
gemmi grep _refine.ls_d_res_high structure.cif

# Get experimental method
gemmi grep _exptl.method structure.cif

# Get entity descriptions
gemmi grep _entity.pdbx_description structure.cif

# Combine tags (append with -a)
gemmi grep _refine.ls_R_factor_R_free -a _refine.pdbx_refine_id structure.cif

# Count values
gemmi grep -c _chem_comp.id structure.cif

# TSV output
gemmi grep --delimiter=$'\t' _entity.formula_weight structure.cif

# Search all mmCIF files recursively
gemmi grep _exptl.method /path/to/mmCIF/

# Suppress block name
gemmi grep -b _software.name structure.cif
```

Key options:
- `-t` – print tag name with values
- `-a TAG` – append another tag value (from same table)
- `-c` – count values instead of printing them
- `-d DELIM` – use delimiter (for CSV/TSV output)
- `-O` – optimise for single-block files (faster)
- `-l` / `-L` – list files with/without the tag
- `-H` – print filename with matches

## CLI: gemmi contact

Search for inter-atomic contacts in a structure. Useful for quickly finding neighbouring atoms, hydrogen bonds, crystal contacts, etc.

```bash
# Find contacts within 3.0 Å (default)
gemmi contact structure.pdb

# Custom distance cutoff
gemmi contact -d 4.5 structure.cif

# Ignore same-residue contacts
gemmi contact --ignore=1 structure.pdb

# Ignore same-chain contacts (inter-chain only)
gemmi contact --ignore=3 structure.pdb

# Ignore contacts between symmetry mates
gemmi contact --nosym structure.pdb

# No hydrogen or water
gemmi contact --noh --nowater structure.cif

# Sort by distance
gemmi contact --sort -d 4.0 structure.pdb

# Analyse biological assembly
gemmi contact --assembly=1 structure.cif

# Count contacts only
gemmi contact --count -d 3.5 structure.pdb

# Use covalent radii-based cutoff
gemmi contact --cov=0.4 structure.pdb
```

Key options:
- `-d DIST` – max distance in Å (default: 3.0)
- `--ignore=N` – skip pairs from same: 0=none, 1=residue, 2=adjacent residues, 3=chain, 4=ASU
- `--nosym` – ignore symmetry mates
- `--noh` – ignore hydrogens
- `--nowater` – ignore water
- `--noligand` – ignore ligands and water
- `--sort` – sort output by distance
- `--count` – print only a count
- `--assembly=ID` – analyse a biological assembly

## CLI: gemmi residues

List residues, chains and entities from a coordinate file.

```bash
# List all residues with atoms
gemmi residues structure.pdb

# Short output (no atoms)
gemmi residues -s structure.cif

# Very short (entity summary)
gemmi residues -ss structure.cif

# List entities
gemmi residues -e structure.cif

# Filter by selection
gemmi residues -m '/1/A/(CYS)' structure.pdb
```

## Python API: Contact Search

The `gemmi.ContactSearch` class provides programmatic contact finding, equivalent to `gemmi contact` on the command line.

```python
import gemmi

st = gemmi.read_structure('structure.pdb')
model = st[0]

# Build neighbour search index
ns = gemmi.NeighborSearch(model, st.cell, 5).populate(include_h=False)

# Create contact search with 4.0 Å radius
cs = gemmi.ContactSearch(4.0)
cs.ignore = gemmi.ContactSearch.Ignore.SameResidue

# Find contacts
results = cs.find_contacts(ns)
for r in results:
    print(f"{r.partner1} - {r.partner2}: {r.dist:.2f} Å")
```

Options for `ContactSearch.Ignore`:
- `Nothing` – no filtering
- `SameResidue` – skip same-residue pairs
- `AdjacentResidues` – skip same or adjacent residue pairs
- `SameChain` – inter-chain contacts only
- `SameAsu` – inter-ASU contacts only

## Python API: Selections (CID syntax)

Gemmi selections use the MMDB/CID syntax: `/model/chain/residues/atoms`. Trailing/leading parts can be omitted.

```python
import gemmi

st = gemmi.read_structure('structure.cif')
sel = gemmi.Selection('A/10-50/CA[C]')

for model in sel.models(st):
    for chain in sel.chains(model):
        for residue in sel.residues(chain):
            for atom in sel.atoms(residue):
                print(f"{chain.name}/{residue.seqid} {atom.name}")
```

Common selection patterns:
- `A` – chain A
- `10-30` – residues 10 to 30
- `(ALA)` – alanine residues
- `CA` or `CA[C]` – Cα carbon atoms
- `[P]` – phosphorus atoms
- `[metals]` – metal atoms
- `:B` – atoms with altloc B
- `;q<0.5` – occupancy below 0.5
- `;b>40` – B-factor above 40
- `(!HOH)` – all residues except water
- `/1/A,B/20-40/CA[C]:,A` – combined filters

## Python API: Superposition

```python
import gemmi

model = gemmi.read_structure('structure.pdb')[0]
poly_a = model['A'].get_polymer()
poly_b = model['B'].get_polymer()
ptype = poly_a.check_polymer_type()

sup = gemmi.calculate_superposition(
    poly_a, poly_b, ptype, gemmi.SupSelect.CaP
)
print(f"RMSD: {sup.rmsd:.3f} Å ({sup.count} atoms)")

# Apply transformation to move chain B onto chain A
poly_b.transform_pos_and_adp(sup.transform)
```

## Python API: Reading and Writing Structures

```python
import gemmi

# Read
st = gemmi.read_structure('input.cif')

# Access hierarchy: Structure → Model → Chain → Residue → Atom
model = st[0]
chain = model['A']
for res in chain:
    for atom in res:
        print(f"{chain.name}/{res.seqid}/{atom.name}: {atom.pos}")

# Write
st.write_pdb('output.pdb')
st.write_minimal_cif('output.cif')
```
