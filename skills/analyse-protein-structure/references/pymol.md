# PyMOL Reference for LLM Agents

This document provides a reference for interacting with PyMOL, focusing on common tasks, selection syntax, and remote control capabilities useful for automated agents.

All PyMOL commands are documented here: 
- https://pymol.org/pymol-command-ref.html
- https://pymolwiki.org/index.php/Category:Commands
- https://wiki.pymol.org/index.php/Category:Commands

## Loading Structures

You can load molecular structures either from a local file or directly from the Protein Data Bank (PDB).

**Loading a local file:**
```pymol
# Load a file and optionally assign it an object name
load /path/to/structure.pdb
load /path/to/structure.pdb, my_protein
```

**Fetching from the PDB:**
```pymol
# Fetch a structure by its 4-letter PDB code (requires internet connection)
fetch 6lfo
fetch 6lfo, my_protein
```

## Remote Control via XML-RPC

PyMOL includes a built-in XML-RPC server, allowing remote programs (like an LLM agent's Python script) to connect and call functions in the running PyMOL instance.

**Starting the PyMOL XML-RPC server:**

```bash
pymol -R -s pymol.log
```

This starts PyMOL and opens port `9123` by default.

**Sending commands via `pymol_xmlrpc_command.py` script:**

For convenience, you can use the provided `pymol_xmlrpc_command.py` script to send semicolon-separated PyMOL commands directly from your terminal.

```bash
# Example: Select a binding site and show it as sticks
./pymol_xmlrpc_command.py "select binding_site, chain A and resi 50-60; show sticks, binding_site"
```

For more complex analyses you can write a Python script to use the built-in `xmlrpc.client` (Python 3) to connect and send commands. 
Any PyMOL `cmd` API function can be called - use `pymol_xmlrpc_command.py` for reference.

*Reference:* [XML-RPC Server Documentation](https://wiki.pymol.org/index.php/XML-RPC_server)
*See also:* [pymol-remote API Script](https://github.com/Croydon-Brixton/pymol-remote)

## Selection Syntax

PyMOL uses a flexible selection language allowing selection by atom/residue/chain identifiers and properties.

*   [Select Command Documentation](https://wiki.pymol.org/index.php/Select)
*   [Selection Algebra Documentation](https://wiki.pymol.org/index.php/Selection_Algebra)

### Basic Select Command
```pymol
select <selection_name>, <selection_expression>
```
*Example:* `select binding_site, chain A and resi 10-20`

### Identifiers & Properties
*   **Models/Objects:** `model my_protein` or `obj my_protein`
*   **Chains:** `chain A` or `c. A`
*   **Residue Numbers:** `resi 1-50` or `i. 1-50`
*   **Residue Names:** `resn ALA+GLY`
*   **Atom Names:** `name CA+CB` or `n. CA+CB`
*   **Secondary Structure:** `ss H` (Helices), `ss S` (Beta sheets), `ss L` (Loops)

### Logical Operators
Selections can be combined with `and`, `or`, and `not` (or `&`, `|`, `!`).

*   *Intersection:* `chain A and not resi 125`
*   *Union:* `name CB or name CG1 or name CG2`
*   *Shorthand Property list:* `name CB+CG1+CG2 and chain A`

**Multi-criteria selections:**
```pymol
# Object + chain + residue range
select name, object_name and chain X and resi 100-150

# Multiple residue ranges (requires OR)
select tm6, obj and chain A and (resi 221-238 or resi 240-254)

# Exclude certain residues using not
select tm6_without_gap, obj and chain A and resi 221-254 and not resi 239
```

### Proximity & Distance Operators
*   `around` or `a.`: Selects atoms within a distance of a target selection.
*   `expand` or `x.`: Selects atoms within a distance, AND includes the target selection.
*   `within ... of` or `w.`: Selects atoms in a selection that are within a distance of another selection.
*   `br.` or `byres`: Expands a selection to whole residues if any part is selected.

*Examples:*
*   Select residues within 5 Å of organic molecules:
    `select close_res, byres (all within 5.0 of organic)`
*   Select water molecules within 3 Å of b-factor < 20:
    `select cold_water, resn HOH within 3.0 of b<20`

### Macro Syntax
You can use a concise slash-separated path format: `/model/segment/chain/residue/atom`
*   `1foo/G/X/444/CA`  (Model 1foo, segment G, chain X, resi 444, name CA)
*   `//A/10-20/` (Any model, chain A, residues 10-20, all atoms)

## Superimposition

PyMOL offers high-level heuristic alignment and low-level specific atom alignment.

### Align / Super (High-Level)

The `align` command performs a sequence alignment followed by a structural superposition.
The `super` command is similar but is better suited for structures with lower sequence similarity.

**Basic Syntax:**
```pymol
align <mobile>, <target>
super <mobile>, <target>
```

**Examples:**
```pymol
# Superimpose model 2 onto model 1
align model2, model1

# Superimpose chain B of model 2 onto chain A of model 1
super model2 and chain B, model1 and chain A
```

### Pair_fit (Lower-Level)

The `pair_fit` command requires defining exactly pairs of atoms to align against each other. The number of atoms in the mobile and target selection must be exactly equal.

**Basic Syntax:**
```pymol
pair_fit <mobile_atoms>, <target_atoms>
```

**Examples:**
```pymol
# Superimpose using subsets of C-alpha atoms from model1 and model2
pair_fit model2 and resi 50-100 and name CA, model1 and resi 1-50 and name CA
```

## Useful Coloring and Visualization Presets

*See the full list of named colors here:* [PyMOL Color Values Documentation](https://pymolwiki.org/Color_Values). 
(Note: While some standard web colors work, PyMOL has a large internal list of named colors, such as `tv_red`, `yellowtint`, `gray50`, or spectral `s000`).

### Amino Acid Coloring (Full Residue)
Useful for highlighting properties manually:

```pymol
# PyMOL doesn't have a single built-in command to color by amino acid type globally.
# However, you can achieve it via sequential commands:

color gray70, all  # Background color
color marine, resn ARG+LYS  # Positively charged
color red, resn ASP+GLU  # Negatively charged
color cyan, resn ASN+GLN+SER+THR  # Polar uncharged
color yellowtint, resn CYS+MET  # Sulfur-containing
color purple, resn PHE+TRP+TYR  # Aromatic
color green, resn ALA+ILE+LEU+VAL  # Aliphatic
color salmon, resn PRO+GLY  # Special cases
```

### Visualizing Hydrogen Bonds and Contacts

PyMOL can search for and display contacts, usually via the `distance` command with specific `mode` parameters.

**Polar Contacts (Hydrogen Bonds):**
```pymol
# Show polar contacts between chain A and chain B
distance hbonds, chain A, chain B, mode=2

# You can hide the labels that accompany the distance measurement
hide labels, hbonds
```

**Heavy Atom Contacts (Clashes / All contacts):**
```pymol
# Show all contacts (default is distance < 3.2A) between two chains
distance contacts, chain A, chain B

# Specifically visualizing clashes with short distances
distance clashes, chain A, chain B, cutoff=2.5
```

### Visualizing a Ligand Binding Site

To visualize the pocket where a specific ligand binds:

```pymol
# Select residues within 5Å of the ligand (assuming resname LIG)
select pocket, byres (all within 5.0 of resn LIG)

# Show the pocket as sticks and hide anything else nearby
hide lines, pocket
show sticks, pocket

# Show hydrogen bonds between the ligand and the pocket
distance pocket_hbounds, resn LIG, pocket, mode=2
hide labels, pocket_hbounds
```

### Highlighting Interface Residues between Chains

Visualizing the interface between a binder and a target:

```pymol
# Select interface residues on chain A close to chain B
select interface_A, byres (chain A within 4.5 of chain B)

# Select interface residues on chain B close to chain A
select interface_B, byres (chain B within 4.5 of chain A)

# Group them together in a single selection
select interface, interface_A or interface_B

show sticks, interface
color orange, interface_A
color lightblue, interface_B
```

### B-factor Coloring (pLDDT)

Color AlphaFold or similar structures by predicted confidence or standard B-factor:

```pymol
# The built-in spectrum command maps property values across a color gradient
spectrum b, blue_white_red, chain A

# For AlphaFold pLDDT, it's typical to use the plddt gradient if a script has installed it.
# Otherwise, recreating the AlphaFold confidence colors manually:
color red, b < 50
color yellow, b > 50 and b < 70
color cyan, b > 70 and b < 90
color blue, b > 90
```

## Viewing the Log and Return Values

When connected over XML-RPC from a Python script, standard output or printed information isn't always returned synchronously. 
To retrieve data programmatically, use specific `cmd.get_*` or API methods:

```python
import xmlrpc.client
pymol = xmlrpc.client.ServerProxy(uri="http://localhost:9123/RPC2")

# Get list of loaded object names
objects = pymol.get_names("all")

# Getting atomic properties by iterating (using a custom python function inside PyMOL namespace)
# Typically, get_fastastr is highly useful for sequence extraction:
fasta = pymol.get_fastastr("chain A")
print(fasta)
```

## Additional Visualization & Editing Commands

* **Grid/Matrix Mode:** Arrange multiple models in a grid layout (similar to ChimeraX's tile).
  ```pymol
  set grid_mode, 1
  ```
* **Split Chains:** Separate chains of a model into individual models.
  ```pymol
  split_chains my_protein
  ```
* **Mutate Residue:** Swap an amino acid using the PyMOL wizard or the `cmd.wizard()` function remotely. Since mutating involves rotamers, it's best done via scripts (e.g., `PyMOL mutagenesis wizard` script libraries).

## Working with Multiple Chains

### Extracting Single Chain
When you only need one chain from a multi-chain PDB, you have a few visual and selection options:

```pymol
# Option 1: Hide other chains
hide everything, complex and not chain A

# Option 2: Use selections to specifically show only one chain
select chain_a_only, complex and chain A
show cartoon, chain_a_only

# Option 3: Use object selection to isolate
select relevant, name1 or name2
```

## Complete Workflows

### Loading, Aligning, and Coloring Multiple Structures

```pymol
# 1. Load structures
load path/to/structure1.pdb, name1
load path/to/structure2.pdb, name2

# 2. Reset view and hide everything
reinitialize   # Or: hide everything, all

# 3. Show cartoon representation
show cartoon, name1
show cartoon, name2

# 4. Define custom colors
set_color custom_red, [0.8, 0.2, 0.2]

# 5. Select and color regions
select region, name1 and chain A and resi 100-150
color custom_red, region

# 6. Set display options
set cartoon_transparency, 0.3
bg_color white

# 7. Align (if needed)
super name2, name1

# 8. Center and zoom
center name1 or name2
zoom name1 or name2, 0.8
```

## Saving Specific Parts of a Structure

To save only a specific selection (e.g., extracting one chain into a new PDB file):

```pymol
# Save chain b to a new PDB file
save target.pdb, chain B
```

## Additional Recipes

See the official Pymol Wiki for more advanced script libraries and workflows.
*   [Script Library](https://wiki.pymol.org/index.php/Category:Script_Library)