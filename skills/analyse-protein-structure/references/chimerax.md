# ChimeraX Reference for LLM Agents

This document provides a reference for interacting with UCSF ChimeraX, focusing on common tasks, selection syntax, and remote control capabilities useful for automated agents.

If the guide below is insufficient to solve a problem, refer to the official documentation at:

* **ChimeraX User Guide:** [https://www.cgl.ucsf.edu/chimerax/docs/user/index.html](https://www.cgl.ucsf.edu/chimerax/docs/user/index.html)
* **ChimeraX Documentation:** [https://www.cgl.ucsf.edu/chimerax/docs/](https://www.cgl.ucsf.edu/chimerax/docs/)

## Remote Control via REST API

ChimeraX can be controlled remotely using its REST API, allowing an LLM agent or external script to execute commands and retrieve information without interacting with the GUI directly.

In ChimeraX, type:

```chimerax
remotecontrol rest start port 51784
```

to start the remote REST server running on a specific port (e.g., `51784`).

### Launching ChimeraX from the command line

**With GUI (for interactive user viewing):**
```bash
# Simple launch — user sees the window
chimerax &
# Then in the ChimeraX command line: remotecontrol rest start port 51784

# Or launch with auto-started REST API:
chimerax --cmd "remotecontrol rest start port 51784" &
```

**Headless / no GUI (for scripted analysis only, user cannot see structures):**
```bash
chimerax --nogui --cmd "remotecontrol rest start port 51784" &
```

> **Important:** Always use the GUI launch (no `--nogui`) when the user wants to *see* structures. Use `--nogui` only for headless scripted analysis where no visual output is needed.

*Reference:* [Remote Control Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/remotecontrol.html)

### Sending Commands via `curl`

Once the server is running, you can send commands to ChimeraX using simple HTTP GET requests. Spaces and special characters must be URL-encoded.

**Example: Open a structure**
```bash
curl "http://127.0.0.1:51784/run?command=open%201af6"
```

**Example: Select residues and color them**
*(Decoded command: `color /A:10-20 red`)*
```bash
curl "http://127.0.0.1:51784/run?command=color%20%2F%20A%3A10-20%20red"
```

> **⚠️ Direct curl REST commands are unreliable for multi-word commands.**
> Commands like `style sel sphere`, `select :50 add`, or compound atomspecs often fail through
> direct `curl GET` with cryptic errors like "Expected a keyword". The same commands work fine
> when executed from ChimeraX's own command line.
>
> **Preferred approach — write a Python script file and `open` it via REST:**
> ```bash
> cat > /tmp/script.py << 'PYEOF'
> from chimerax.core.commands import run
> run(session, "select (:50 & :tyr) | (:76 & :tyr)")
> run(session, "style sel sphere")
> run(session, "color sel red")
> session.logger.info("Done")
> PYEOF
> curl "http://127.0.0.1:51784/run?command=open%20%2Ftmp%2Fscript.py"
> ```
> Python scripts parse commands properly, provide clear stack traces on error,
> and support `session.logger.info()` for debugging.

### Executing Python Scripts

Python scripts are the most reliable way to control ChimeraX remotely. Write a `.py` file
on disk and open it via REST:

```bash
cat > /tmp/my_script.py << 'PYEOF'
from chimerax.core.commands import run

run(session, "open 1ktk")
session.logger.info(f"Models: {len(session.models)}")

from chimerax.atomic import AtomicStructure
for m in session.models:
    if isinstance(m, AtomicStructure):
        chain_ids = sorted(set(r.chain_id for r in m.residues))
        session.logger.info(f"#{m.id_string}: chains {','.join(chain_ids)}, {len(m.residues)} residues")
PYEOF
curl -s "http://127.0.0.1:51784/run?command=open%20%2Ftmp%2Fmy_script.py"
```

**Python API patterns for model/chain inspection:**
| Purpose | Code |
|---------|------|
| Check if a model is atomic | `isinstance(m, AtomicStructure)` |
| Get chain IDs | `set(r.chain_id for r in m.residues)` |
| Get model ID string | `m.id_string` (returns `"1.1"`, `"2"`, etc.) |
| Log to ChimeraX console | `session.logger.info("...")` |
| Log errors | `session.logger.error("...")` |

> **Note:** `m.chains` and `m.chain_ids` do **not** exist on `AtomicStructure`.
> Always iterate `m.residues` to get chain information.

## Loading Structures

You can load structural files either from your local filesystem or directly fetch them from databases like the PDB.

**Loading a local file:**
```chimerax
# Open a local PDB or mmCIF file
open /path/to/structure.pdb
open /path/to/structure.cif
```

**Fetching from databases:**
```chimerax
# Fetch from the Protein Data Bank
open 6lfo

# Fetch from AlphaFold Database (by UniProt ID)
# e.g. open af:P00533 
```

*Reference:* [Open Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/open.html)

### Common visualization commands

These are verified ChimeraX commands for common representation changes:

```chimerax
# Cartoon representation (default is fine — no need to change style)
cartoon          # show cartoon for selected/visible models
hide atoms       # hide atom spheres
show cartoons    # explicit show

# Coloring
color bychain    # each chain a different color
color bymodel    # each model a different color
color byhetero   # heteroatoms colored differently

# Layout
tile all columns 8 spacingFactor 1.0   # grid layout for many models

# Superimposition
matchmaker #2-48 to #1    # align models onto a reference
```

> **Pitfall:** ChimeraX's `cartoon style` command syntax varies by version and expects specific subcommand keywords. If it errors, the default cartoon representation is already suitable — skip the style change rather than guessing syntax.
>
> **Style command gotchas:**
> - `style sel spheres` (plural) fails with "Expected a keyword" — use `style sel sphere` (singular)
> - `style sel cartoon` fails — use `show cartoons` instead
> - `style sel stick` may fail — use `style stick` without `sel` if selection is active
> - When commands fail through REST API or scripts, prefer writing a Python script file and running `open /path/to/script.py` which gives more reliable parsing and error messages via `session.logger.info()`

## Selection syntax (AtomSpec)
ChimeraX uses a powerful hierarchical selection language (AtomSpec). 
* [Selection Overview](https://www.cgl.ucsf.edu/chimerax/docs/user/selection.html)
* [AtomSpec Reference](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/atomspec.html)

### Hierarchy and Syntax

The general syntax is `#model/chain:residue@atom`.

* `#` specifies model number (e.g., `#1`, `#2.1`)
* `/` specifies chain ID (e.g., `/A`, `/B`)
* `:` specifies residue number or name (e.g., `:10-20`, `:LYS`)
* `@` specifies atom name (e.g., `@CA`, `@N,O`)

### Common Examples

* **Specific chain:** `/A`
* **Multiple chains:** `/A,B,C` *(commas separate chain IDs within the model)*
* **Residue range:** `:1-50`
* **Specific residue names:** `:ALA,GLY` *(commas separate residue names)*
* **Alpha carbons only:** `@CA`
* **Residues 10-20 in chain A of model 1:** `#1/A:10-20`
* **Proximity/Zone:** `zone /A:10 5.0` (selects atoms within 5.0 Å of chain A residue 10)
* **Combining selectors (AND):** `:LYS & /A` (Lysines in chain A)
* **Combining selectors (OR):** `:LYS | :ARG` (Lysines or Arginines)
* **Negation (NOT):** `~protein` (non-protein atoms)
* **Proximity Selection:** `select :sideonly/1 & /2 :<4` (Select sidechains in chain 1 within 4Å of chain 2)

### Selection Gotchas

**1. `select :X add` does NOT work.** The `add` keyword is not recognized.
   Instead of incrementally building a selection, use the OR operator `|` in one command:
   ```chimerax
   # ✗ Wrong: select :50; select :76 add; select :77 add
   # ✓ Correct:
   select :50 | :76 | :77
   ```

**2. Commas in model/chain atomspecs separate multiple items within ONE model,**
   not across different models:
   ```chimerax
   # ✓ Correct: chains B AND D within model 3
   matchmaker #3/B,D to #2/A,C
   
   # ✗ Wrong: two separate atomspecs separated by comma (will error)
   matchmaker #3/B,#3/D to #2/A,#2/C
   ```

### Selecting a Specific Residue Type at a Specific Position

When a user asks for "Tyr50" (a specific residue type at a specific position), you **cannot** use `:TYR50` — this is **not valid** ChimeraX AtomSpec syntax. The `:` prefix accepts either a residue number OR a residue name, never both combined.

**Correct approach — use AND (`&`) to combine number and type:**
```chimerax
# Select Tyr at position 50 (verifies residue 50 is actually tyrosine)
:50 & :tyr

# Multiple specific residues: Tyr50, Tyr76, Ile77, Tyr85, Tyr87, Asp183
(:50 & :tyr) | (:76 & :tyr) | (:77 & :ile) | (:85 & :tyr) | (:87 & :tyr) | (:183 & :asp)
```

**Why verify the residue type?** Using `:50` alone selects *whatever* residue is at position 50, which may not be tyrosine (especially across multiple chains where numbering can differ). Always confirm with `& :tyr` that the residue matches the expected type.

**Warning — residue numbers match across ALL chains:** `:50` without a chain specifier selects residue 50 in every chain of the model. If you need a specific chain, always include it: `/A:50 & :tyr`.

## Superimposition

ChimeraX provides high-level and lower-level commands to superimpose structures.

### Matchmaker (High-Level)

The `matchmaker` command superimposes structures based on sequence alignment and structural criteria.

**Key concepts:**
You define a **reference** structure (which stays in place) and one or more structures to move (the **match** structure).

**Basic Syntax:**
```chimerax
matchmaker #reference to #match
```

**Examples:**
* Superimpose model 2 onto model 1:
  ```chimerax
  matchmaker #2 to #1
  ```
* Superimpose chain B of model 2 onto chain A of model 1:
  ```chimerax
  matchmaker #2/B to #1/A
  ```
* Superimpose chain B of models 1-100 onto chain B of model 101:
  ```chimerax
  matchmaker #1-100/B to #101/B
  ```
* Superimpose multiple chains at once (comma-separate chain IDs within the model):
  ```chimerax
  matchmaker #3/B,D to #2/A,C
  ```
  This aligns chains B and D of #3 onto chains A and C of #2. All chains within
  each model move rigidly together — useful for comparing complexes where you want
  one set of chains to drive the alignment and others to follow.

  **Note:** `#3/B,#3/D` (comma between model+chain pairs) **will NOT work** —
  commas only separate chain IDs *inside* the model specifier.

### Align (Lower-Level)

The `align` command is a lower-level alternative to `matchmaker` that directly superimposes specific sets of atoms you define, rather than relying on sequence alignment. This is useful when sequences are very different or you want to align specific functional groups.

**Basic Syntax:**
```chimerax
align <match_atoms> to <reference_atoms>
```
Note: Both sets must have the exact same number of atoms.

eg to superimpose using subsets of C-alpha atoms from molecule #1 and #2:
```chimerax
align #1:1-50@CA to #2:50-100@CA
```

*Reference:* 
* [Matchmaker Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/matchmaker.html)
* [Align Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/align.html)

## Useful Coloring and Visualization Presets

Below are examples of how to achieve common visualization tasks using the ChimeraX command line.

### Amino Acid Coloring (Sidechains Only)
Color protein sidechains by their amino acid properties while leaving the backbone structure unchanged:

```chimerax
# protein "amino" color scheme (sidechains only)
color :ala & sideonly #c8c8c8
color :arg & sideonly #145aff
color :asn,gln & sideonly #00dcdc
color :asp,glu & sideonly #e60a0a
color :cys & sideonly #e6e600
color :gly & sideonly #ebebeb
color :his & sideonly #8282d2
color :ile,leu,val & sideonly #0f820f
color :lys & sideonly #145aff
color :met & sideonly #e6e600
color :phe & sideonly #3232aa
color :pro & sideonly #dc9682
color :ser,thr & sideonly #fa9600
color :trp & sideonly #b45ab4
color :tyr & sideonly #3232aa
color :asx,glx & sideonly #ff69b4
```

### Amino Acid Coloring (Full Residue)
Color the entire residue (backbone and sidechain):

```chimerax
# protein "amino" color scheme (full residue)
color protein #bea06e
color :ala #c8c8c8
color :arg #145aff
color :asn,gln #00dcdc
color :asp,glu #e60a0a
color :cys #e6e600
color :gly #ebebeb
color :his #8282d2
color :ile,leu,val #0f820f
color :lys #145aff
color :met #e6e600
color :phe #3232aa
color :pro #dc9682
color :ser,thr #fa9600
color :trp #b45ab4
color :tyr #3232aa
color :asx,glx #ff69b4
```

### Visualizing Hydrogen Bonds and Contacts

ChimeraX can identify and display non-covalent interactions like hydrogen bonds and steric clashes (tight contacts).

**Hydrogen Bonds:**
```chimerax
# Show all hydrogen bonds in the structure
hbonds

# Show hydrogen bonds between chain A and chain B
hbonds /A restrict /B

# Find hydrogen bonds and print details to the log
hbonds /A restrict /B reveal true makePseudobonds false log true
```

*Reference:* [hbonds Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/hbonds.html)

**Contacts (Clashes):**
```chimerax
# Show atomic contacts between chain A and chain B
contacts /A restrict /B

# Find tight contacts (clashes) specifically
clashes /A restrict /B
```

*Reference:* [contacts/clashes Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/clashes.html)

### Visualizing a Ligand Binding Site

To visualize the pocket where a specific ligand (e.g., named "LIG") binds:

```chimerax
# Select residues within 5Å of the ligand
select zone :LIG 5.0

# Show the atoms and bonds of the selected residues
show sel
style sel stick

# Show hydrogen bonds between the ligand and the binding pocket
hbonds :LIG restrict sel
```

For more advanced binding site visualization techniques, refer to the official tutorial:
*Reference:* [Binding Sites Tutorial](https://www.cgl.ucsf.edu/chimerax/docs/user/tutorials/binding-sites.html)

### Highlighting Interface Residues between Chains

To quickly identify and visualize residues at the interface between two chains (e.g., a binder and a target):

```chimerax
# Select interface between chain A and B in model 1
interfaces select #1/A contacting #1/B bothSides true

# Show selected atoms
show sel

# Change selected atoms/bonds to stick representation
style sel stick

# Color to differentiate
color bychain

# Hide all models except #1, or show specific parts
hide all models
show #1 models
```

### B-factor Coloring

Color structures based on their predicted confidence (pLDDT) or B-factor values:

```chimerax
# Color models 1-100 chain A using the AlphaFold red-yellow-blue palette
color by bfactor #1-100/A palette alphafold

# Or, use a custom palette
color byattribute bfactor protein palette blue:red:yellow:white
```

*Reference:* [Color Command Documentation](http://rbvi.ucsf.edu/chimerax/docs/user/commands/color.html)

### Showing Electron Density Maps (X-ray)

Visualize electron density around a specific structure:

```chimerax
# Assuming structure is model #1, and density 'volume' is #2
open 6lfl from pdb
open 6lfl from eds

# Cover the atoms of model #1 with the density volume #2
volume cover #2 atomBox #1
# Limit the shown volume to within 2.0A of model #1
volume zone #2 near #1 range 2.0
```

### Model Manipulation — Split, Combine, Close

ChimeraX has **no `copy` command**. To rearrange chains into new model groupings:

```chimerax
# 1. Split all chains into individual models (#1.1, #1.2, ...)
split #1

# 2. Combine specific chains into a combined model
combine #1.1 #1.3 #1.5   # creates #2 with chains A, C, E
combine #1.2 #1.4 #1.6   # creates #3 with chains B, D, F

# 3. Close originals if no longer needed
close #1
```

**Important:** After `split`, chain models use dot notation (`#1.1`, `#1.2`, etc.).
After `combine`, the original models still exist — `close` them explicitly.
`combine` with space-separated model IDs, not comma-separated.

### Python Scripting via ChimeraX API (Multi-model interfaces)

For more complex logic, write Python scripts and execute via `open /path/to/script.py`.
Here is an example to show interface residues between chain A and B across multiple models:

```python
# ChimeraX Python Script
# - show interface residues between chain A and B for every model

from chimerax.core.commands import run

all_models = session.models
run(session, "select clear")

for model in all_models:
    session.logger.info(f"==> Processing model: #{model.id_string} ({model.name})")

    try:
        command = f"interfaces select #{model.id_string}/A contacting #{model.id_string}/B bothSides true"
        run(session, command)
        run(session, "show sel atoms")
        session.logger.info(f"    SUCCESS: Processed model {model.id_string}.")

    except Exception as e:
        session.logger.error(f"    FAILED: Could not process model #{model.id_string}.")
        session.logger.error(f"    Reason: {e}")
        continue

session.logger.info("--- Finished Model Loop ---")
```

## Secondary Structure Assignment

You can calculate and assign secondary structure using the `dssp` command. To report the assignments directly in the log (so that an LLM agent viewing the log can read them), use the `report true` flag:

```chimerax
# Calculate secondary structure and print assignments to the log
dssp #1 report true
```

*Reference:* [DSSP Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/dssp.html)

## Viewing the Log for Useful Info

Many commands in ChimeraX output useful information (like distances, RMSD values,
alignment scores, or assignments) to the log. You can retrieve the log contents to
inspect command results.

```chimerax
# Save the log to an HTML file, then read it with a text browser or curl
log save /tmp/chimera_log.html

# Clear the log before running a command whose output you want clean
log clear
```

> **Note:** `log text` requires a keyword argument and is **not** a simple
> "print log contents" command. Use `log save /path/to/file.html` instead.
> From a Python script, use `session.logger.info()` and write results to a file you
> can read with bash.

**Capturing RMSD/alignment results in a Python script:**
```python
from chimerax.core.commands import run

# matchmaker output goes to the log; save it to read later
run(session, "log clear")
run(session, "matchmaker #3/B,D to #2/A,C")
run(session, "log save /tmp/chimera_log.html")

# Now read /tmp/chimera_log.html with bash to extract RMSD values
```

*Reference:* [Log Command Documentation](https://www.cgl.ucsf.edu/chimerax/docs/user/commands/log.html)

## Additional Visualization & Editing Commands

* **Tile Models:** Arrange multiple loaded models (e.g., 96 binders) in a grid layout.
  ```chimerax
  tile all columns 12 spacingFactor 1.0
  ```
* **Split Chains:** Separate chains of a model into individual models (e.g., `#1` becomes `#1.1, #1.2` etc.) to allow independent superimposition.
  ```chimerax
  split #1
  ```
  *(Reference: [Split documentation](https://www.cgl.ucsf.edu/chimera/experimental/split_molecule/split.html))*
* **Mutate Residue:** Swap an amino acid using the `swapaa` command.
  ```chimerax
  # Non-interactive mode (mutate to Lysine)
  swapaa /E:14 lys

  # Interactive mode (opens a GUI to select the best rotamer)
  swapaa interactive /E:14 lys
  ```
* **Displaying Cavities:** A guide for displaying cavity surfaces can be found [here](https://www.jameslingford.com/blog/chimerax-cavity-surfaces/).
* **UMAP Analysis:** Note - figure out how to use the built-in C-alpha based UMAP from the `similarstructures` command with arbitrary loaded models rather than via a foldseek search.

## Saving Specific Parts of a Structure

To save only a specific selection (e.g., extracting one chain into a new PDB file):

```chimerax
# Select only chain B
select /B

# Save the selection to a formatted PDB file
save ~/tmp/7SCT_target.pdb format pdb selectedOnly true
```

## Additional Resources

* **ChimeraX Recipes:** A curated collection of scripts and workflows for common tasks: [https://rbvi.github.io/chimerax-recipes/](https://rbvi.github.io/chimerax-recipes/), eg:
  * [Show a protein binding pocket surface](https://rbvi.github.io/chimerax-recipes/binding_pocket/binding_pocket.html)
  * [Show surface exposed hydrophobic residues](https://rbvi.github.io/chimerax-recipes/hydrophobicity/hydrophobicity.html)
  * [Color alpha-helices by lipophilicity](https://rbvi.github.io/chimerax-recipes/mlp_helices/mlp_helices.html)
  * [Search AlphaFold database for transmembrane proteins](https://rbvi.github.io/chimerax-recipes/alphafold_search/alphafold_search.html)
  * [Lookup residues by chain identifier and residue number](https://rbvi.github.io/chimerax-recipes/lookup_residues/lookup_residues.html)
  * [Place peptide linkers using molecular dynamics](https://rbvi.github.io/chimerax-recipes/linker/linker.html)
