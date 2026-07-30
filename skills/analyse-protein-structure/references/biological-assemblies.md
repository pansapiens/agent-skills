# Biological Assemblies, Asymmetric Units and Crystal Contacts

Contact analysis tools (arpeggio, gemmi, PyMOL, ChimeraX) analyse **exactly the coordinates you hand them**. They do not know about crystallographic symmetry unless you ask, and they do not know which chain–chain contacts are biologically meaningful. Getting this wrong produces confidently wrong answers:

- **Missing a real interface** — a homodimer whose 2-fold axis coincides with a crystallographic axis has only *one* subunit in the deposited file. The dimer interface does not exist in those coordinates.
- **Reporting packing artefacts as biology** — two chains in the deposited file are not necessarily a biological complex.
- **Analysing a partial site** — a ligand or metal site can be completed by a symmetry mate.

## Terms

| Term | Meaning |
|------|---------|
| **Asymmetric unit (ASU)** | The coordinates actually deposited (what you get from `files.rcsb.org/download/XXXX.cif`). The smallest unit from which the whole crystal is built by applying space-group symmetry. Has no guaranteed biological meaning. |
| **Unit cell / space group** | The repeating box and its symmetry operators (`_cell.*`, `_symmetry.space_group_name_H-M`; `CRYST1` in PDB format). |
| **Symmetry mate** | A copy of the ASU produced by a space-group operator plus a lattice translation. Infinitely many exist; a handful touch the ASU. |
| **Biological assembly** (biological unit, quaternary structure) | The physiologically relevant oligomer, annotated by the depositor and/or predicted by software (usually PISA). Defined in mmCIF by `_pdbx_struct_assembly`, `_pdbx_struct_assembly_gen`, `_pdbx_struct_oper_list`; in PDB format by `REMARK 350`. An entry may define several. |
| **Crystal contact** (lattice contact, packing contact) | An interface that exists only because of crystal packing — present in the lattice, absent in solution. |
| **Special position** | An atom sitting on a symmetry element (axis, mirror, centre). Its symmetry images coincide with itself, so symmetry-aware contact searches report spurious ~0 Å self-contacts. |

**Non-crystallographic structures:** cryo-EM, NMR and predicted models have no crystal lattice (space group is `P 1` or absent), so there are no symmetry mates or crystal contacts — but assemblies are still annotated for PDB entries, and the deposited model is not always the full assembly. For AlphaFold/Boltz/RFdiffusion outputs, the oligomeric state is an *input assumption* of the prediction, not evidence.

## How the ASU relates to the assembly

All of these relationships are common. Verified examples:

| Relationship | Example | ASU polymer chains | Assembly 1 |
|---|---|---|---|
| ASU **is** the assembly | 4HHB (`P 1 21 1`) | A, B, C, D | tetrameric, `oper_expression` = `1` |
| ASU is **half** the assembly | 1HHO (`P 41 21 2`) | A, B | tetrameric, `oper_expression` = `1,2` |
| ASU is **one subunit** of an oligomer | 3HVP (`P 41 21 2`) | A | dimeric, `oper_expression` = `1,2` |
| ASU holds **two copies** of the assembly | 12E8 (Fab) | L, H, M, P | assembly 1 = L+H; assembly 2 = M+P |
| ASU chains are **not** a complex | 6RXG (`P 1`) | A, B | assembly 1 = A (monomeric); assembly 2 = B (monomeric) |
| ASU is a **fragment of a particle** | 1CWP (virus) | 6 chains | "complete icosahedral assembly", 360-meric, `oper_expression` = `(1-60)` |

Read `oper_expression`: `1` means "use the deposited coordinates as-is"; anything else means symmetry/NCS operators must be applied to build the assembly. If it is not just `1`, **the deposited file does not contain the assembly**.

For 6RXG the two chains in the ASU are in contact (114 atom pairs within 4 Å) and look like a homodimer, but the depositor annotated two separate *monomeric* assemblies — so every A–B contact computed from the deposited file is a crystal contact. Its assembly record also has no `interface_ids`, which is itself the giveaway.

## Procedure: analysing the right assembly

### 1. Read the assembly annotation before analysing anything

From the RCSB API (no download needed):

```bash
# Which assemblies exist?
curl -s "https://data.rcsb.org/rest/v1/core/entry/1HHO" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); \
print(d['rcsb_entry_container_identifiers']['assembly_ids'], \
d.get('symmetry',{}).get('space_group_name_H_M'), \
d['rcsb_entry_info']['deposited_polymer_entity_instance_count'],'chains in ASU')"

# What is assembly 1?
curl -s "https://data.rcsb.org/rest/v1/core/assembly/1HHO/1" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); a=d['pdbx_struct_assembly']; \
print(a['oligomeric_details'], a['oligomeric_count'], a['details'], a.get('method_details')); \
print(d['pdbx_struct_assembly_gen'])"
```

Or from a local file:

```bash
gemmi grep -t _pdbx_struct_assembly.oligomeric_details -a _pdbx_struct_assembly.details 1HHO.cif
gemmi grep -t _pdbx_struct_assembly_gen.oper_expression -a _pdbx_struct_assembly_gen.asym_id_list 1HHO.cif
gemmi grep -t _symmetry.space_group_name_H-M 1HHO.cif
grep "^REMARK 350" 1HHO.pdb    # PDB-format equivalent
```

Interpret `_pdbx_struct_assembly.details`:

| Value | Confidence |
|---|---|
| `author_and_software_defined_assembly` | Strongest — depositor and PISA agree |
| `author_defined_assembly` | Depositor's claim only |
| `software_defined_assembly` | Prediction only (usually PISA); treat with more caution |
| `complete icosahedral assembly`, `representative helical assembly`, `icosahedral asymmetric unit`, ... | Viral/helical entries — check whether this assembly is the whole particle or a fragment (`oligomeric_count` tells you) |

### 2. Choose the assembly that matches your question

- More than one assembly usually means the ASU contains multiple independent copies (12E8) or genuinely different biological forms.
- If your question is about a hetero-complex, confirm **both partners are in the same assembly** — an entry can define one assembly per protein (6RXG).
- If two chains are in *different* assemblies, their interface is a crystal contact, full stop.

### 3. Download the pre-expanded assembly (preferred) or expand it yourself

```bash
# mmCIF assembly — always available, use this by default
curl -s "https://files.rcsb.org/download/1HHO-assembly1.cif.gz" | gunzip -c >1HHO-assembly1.cif

# Legacy PDB-format assembly (pdb1 = assembly 1, pdb2 = assembly 2) — see the MODEL trap below.
# Not generated for large assemblies (e.g. 4V6X.pdb1.gz returns 404)
curl -s "https://files.rcsb.org/download/1HHO.pdb1.gz" | gunzip -c >1HHO.pdb1

# Or expand locally from the ASU using the file's own assembly metadata
gemmi convert --assembly=1 1HHO.cif 1HHO-asm1.cif
```

Never build an assembly by hand-applying matrices unless you have no alternative.

### 4. Verify what you actually got

```bash
gemmi residues -ss 1HHO-assembly1.cif     # chain list — count them
gemmi residues -c 1HHO-assembly1.cif      # chain IDs only
```

The polymer chain count must match `oligomeric_count`. If it matches the ASU count instead, the expansion did not happen.

### 5. Re-map chain names — they change on expansion

The three routes give three different chain namings for the same 1HHO tetramer:

| Route | Polymer chain IDs | Models |
|---|---|---|
| `1HHO-assembly1.cif` (RCSB) | `A`, `B`, `A-2`, `B-2` | 1 |
| `gemmi convert --assembly=1 … .cif` | `A1`, `B1`, `A2`, `B2` | 1 |
| `gemmi convert --assembly=1 … .pdb` | `A`, `B`, `C`, `D` | 1 |
| `1HHO.pdb1` (RCSB legacy) | `A`, `B` **and** `A`, `B` again | **2** |

Any `--chains` or `-s` argument written for the ASU is stale after expansion. Note that arpeggio's chain-only selector needs three fields, and hyphens are fine in the chain field: `-s /A-2//`, `-s /A1//`.

### 6. Sanity check the interfaces you found

See "Telling crystal contacts from biological interfaces" below, and compare with solution evidence (SEC-MALS, native MS, SAXS, mutagenesis) from the primary publication. The assembly annotation is an inference, not a measurement — authors and PISA are both sometimes wrong.

## The `.pdb1` multi-MODEL trap

RCSB legacy PDB-format assembly files put each symmetry copy in a **separate `MODEL` record and reuse the same chain IDs**. Almost every tool reads only the first model, so you silently analyse the ASU while believing you analysed the assembly.

Verified on 1HHO (haemoglobin α₂β₂, ASU = αβ):

```bash
# 1HHO.pdb1 contains 2 models, each with chains A and B
grep -c "^MODEL" 1HHO.pdb1          # 2

# gemmi contact has no --format option, so rename to .pdb first
cp 1HHO.pdb1 1hho_asm1.pdb

# Inter-chain contacts: multi-MODEL pdb1 == the ASU alone
gemmi contact --count -d 4 --noh --nowater --nosym --ignore=3 1hho_asm1.pdb    # 167.5
gemmi contact --count -d 4 --noh --nowater --nosym --ignore=3 1HHO.cif         # 167.5  (ASU)
gemmi contact --count -d 4 --noh --nowater --nosym --ignore=3 --assembly=1 1HHO.cif  # 443
```

Arpeggio behaves the same way — on the multi-MODEL file it reports only the α1β1 interface (`A-B`), while on a properly expanded assembly it also finds the α1β2, α1α2 and β1β2 interfaces:

```
# pdbe-arpeggio on 1HHO.pdb1 (multi-MODEL)   -> chain pairs: A-B only
# pdbe-arpeggio on gemmi-expanded assembly   -> A1-B1, A2-B2, A1-B2, A2-B1, A1-A2, B1-B2
```

**Rule:** prefer `-assembly1.cif.gz`, or `gemmi convert --assembly=1`. If you must use a `.pdb1` file, check `grep -c ^MODEL` first, and note that gemmi needs `--format=pdb` because it cannot infer the format from the `.pdb1` extension.

## Telling crystal contacts from biological interfaces

In order of authority:

**1. Assembly membership.** If an interface is not inside any annotated assembly, it is a crystal contact. This is the primary criterion.

**2. Interface metrics from RCSB.** RCSB pre-computes every pairwise interface *within* each assembly, with buried area and core residue counts:

```bash
# The GraphQL query must be a single-line JSON string — build it with a heredoc
cat >interfaces.json <<'EOF'
{"query":"{ assembly(entry_id: \"1HHO\", assembly_id: \"1\") { interfaces { rcsb_interface_container_identifiers { interface_id } rcsb_interface_info { interface_area interface_character num_interface_residues num_core_interface_residues } rcsb_interface_partner { interface_partner_identifier { asym_id } } rcsb_interface_operator } } }"}
EOF

curl -s -X POST https://data.rcsb.org/graphql -H "Content-Type: application/json" -d @interfaces.json \
  | python3 -c "
import sys, json
for i in json.load(sys.stdin)['data']['assembly']['interfaces']:
    info = i['rcsb_interface_info']
    print(i['rcsb_interface_container_identifiers']['interface_id'],
          [p['interface_partner_identifier']['asym_id'] for p in i['rcsb_interface_partner']],
          i['rcsb_interface_operator'],
          f\"{info['interface_area']:.0f} A2\", info['num_interface_residues'], 'res',
          info['num_core_interface_residues'], 'core', info['interface_character'])"
```

The per-interface REST endpoint is also available: `https://data.rcsb.org/rest/v1/core/interface/1HHO/1/1` (entry / assembly / interface), with the interface IDs listed under `rcsb_assembly_container_identifiers.interface_ids` on the assembly record.

For 1HHO assembly 1 this returns:

| Interface | Partners | Operators | Area (Å²) | Interface res | Core res |
|---|---|---|---|---|---|
| 1 | A–B | same copy | 882 | 49 | 11 |
| 2 | A–B | different copies | 492 | 29 | 0 |
| 3 | A–A | different copies | 376 | 22 | 0 |
| 4 | B–B | different copies | 163 | 16 | 0 |

`rcsb_interface_operator` tells you whether an interface exists in the deposited coordinates or only after symmetry expansion (interfaces 2–4 here). Note all four are *biological* (they are inside the tetramer) — area alone does not decide relevance; membership does.

**3. Heuristics** (use only when annotation is absent or suspect — e.g. for your own crystal structures):

| Signal | Suggests crystal contact | Suggests biological interface |
|---|---|---|
| Buried surface area | ≲ 400 Å² per side | ≳ 800–1000 Å², often much more |
| Core (fully buried) interface residues | none | several, forming a hydrophobic core |
| Chemistry | polar, water-mediated, few H-bonds | hydrophobic patch plus specific H-bonds/salt bridges |
| Sequence conservation at interface | not conserved | conserved beyond the rest of the surface |
| Symmetry | generated by a screw axis or pure translation, propagating indefinitely through the lattice | closed point-group symmetry (a finite oligomer) |
| Recurrence | interface differs between crystal forms of the same/homologous protein | same interface in independent crystal forms |

Caveats: weak transient interfaces (signalling, enzyme–substrate) can be small and poorly conserved; large crystal contacts do occur, especially in high-solvent-content crystals.

**4. External servers** for a second opinion:

- **PDBePISA** — https://www.ebi.ac.uk/pdbe/pisa/ — interface areas, ΔG of dissociation, assembly prediction.
- **EPPIC** — https://www.eppic-web.org/ — geometric + evolutionary classification of each lattice interface as biological or crystal.
- **ProtCID** — http://dunbrack2.fccc.edu/protcid/ — whether an interface recurs across crystal forms and homologues (strong evidence for biology).

## Finding crystal contacts with gemmi

`gemmi contact` is symmetry-aware **by default** — unlike arpeggio, it generates symmetry mates from `CRYST1`/`_symmetry` and reports contacts to them.

```bash
# Everything, including symmetry mates (default)
gemmi contact -d 4.0 --noh --nowater 1HHO.cif

# Only contacts within the deposited coordinates
gemmi contact -d 4.0 --noh --nowater --nosym 1HHO.cif

# Only contacts to symmetry mates, i.e. candidate crystal contacts
gemmi contact -d 4.0 --noh --nowater --ignore=4 --sort 1HHO.cif

# Contacts within a biological assembly
gemmi contact -d 4.0 --noh --nowater --assembly=1 1HHO.cif
```

Output columns end with two PDB-style symmetry codes and the distance:

```
             N   VAL A   1                 OXT ARG A 141     1555   8555  2.24
```

The codes are `nnnttt`: operator number `nnn` followed by unit-cell translations encoded with 5 as zero (`555` = no translation). `1555` is the identity — the atom as deposited; `8555` is symmetry operator 8, i.e. a symmetry mate. Both codes equal to `1555` means a contact within the deposited coordinates.

**Special positions:** an atom on a symmetry axis produces near-zero-distance contacts with its own image (in 1HHO the phosphate ion gives `PO4 A 142` vs `PO4 A 142` at 0.02 Å between operators `1555` and `8555`). Discard contacts between an atom and itself under a different operator.

## Checklist

- [ ] Checked space group and whether the method even has a crystal lattice
- [ ] Listed the assemblies and read `oligomeric_details`, `details`, `oper_expression`
- [ ] Confirmed the deposited file is/is not the assembly (`oper_expression` = `1`?)
- [ ] Downloaded/expanded the assembly rather than reconstructing it
- [ ] Counted polymer chains in the file and matched them to `oligomeric_count`
- [ ] Checked `grep -c ^MODEL` if using a `.pdb1`/`.pdb2` file
- [ ] Updated chain IDs in `--chains` / `-s` arguments after expansion
- [ ] For any interface of interest: inside an annotated assembly? area and core residues plausible?
- [ ] Cross-checked oligomeric state against the paper's solution data

## References

- RCSB — Biological assemblies: https://www.rcsb.org/docs/general-help/assemblies
- PDBx/mmCIF assembly categories: https://mmcif.wwpdb.org/dictionaries/mmcif_pdbx_v50.html
- gemmi symmetry and assemblies: https://gemmi.readthedocs.io/en/latest/symmetry.html
- Krissinel & Henrick (2007) *Inference of macromolecular assemblies from crystalline state*, J Mol Biol 372:774 (PISA)
- Bliven et al. (2018) *Automated evaluation of quaternary structures from protein crystals*, PLoS Comput Biol 14:e1006104 (EPPIC)
- Xu & Dunbrack (2020) ProtCID, Nat Commun 11:711
