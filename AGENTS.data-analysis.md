
## JOURNAL.md

Document each step you take with reproducible commands in a datetime stamped (`date -Is`) JOURNAL.md file. JOURNAL.md should be considered append-only.

eg:

----

```markdown
## 2026-06-19T12:11:39+10:00

Plots in the "Save outputs" cell now also write a PNG alongside each PDF (`dpi=200`), since PNGs
are easier to drop into chat/slides/docs than PDFs. Updated README.md's Files/Outputs sections to
say "PDF and PNG" instead of "PDF".

Verified with `uvx marimo check analysis.py` (0 issues) and `python analysis.py` (same counts:
131/40/57/6); confirmed `plots/` now contains both `.pdf` and `.png` for all 7 figures.
 
```bash
uvx marimo check analysis.py
source .venv/bin/activate && python analysis.py   # writes plots/*.pdf and plots/*.png
```

```

----

## Overview README.md

When done, or at critical checkpoints:

 Write a summary of what we are showing here in a README.md
 - give a short overall aim or goal of the analysis
 -  you may include brief key results, tables, findings here, but keep it concise and put full results in external files
 - explain setup instructions, software and data dependencies, expected hardware requirements
 - explain each file/directory
 - provide the 'happy path' to reproduce the analysis
	 - rather than follow the JOURNAL.md exactly, where we may have had many dead-ends, refactors and reorganisations, README.md should contain the shortest path to completing the analysis, as if we had done it successfully in one shot with no diversions or errors

## File organisation

While each project may have it's own needs, here are some guidelines.

Nested folder hierarchies are better than many files in the root folder (within reason). You may need to periodically reorganise the folder hierarchy or file/folder naming - if so, do this carefully and ensure any associated notes are updated (JOURNAL.md, scripts, README.md) - generally do a git commit prior to reorganising.

- `scripts/` - for utility and analysis scripts
- `data/` - input data, typically immutable. Nested by type or other logical categorisation (eg `data/sequences` or `data/pdbs` or `data/strains`)
- `results/` or `output/` - nested by specific analysis

## Marimo notebooks

Read the `marimo-notebook` skill to make sure you understand the constraints of marimo - it's not like a regular Jupyer notebook, global variables in a cell cannot be redefined in otther cells.

## Useful skills

Be aware of the agent skills:
- analyse-protein-strucure
- exploratory-data-analysis
- data-analysis skills
	- scientific-visualization
	- statistical-analysis
	- statsmodels
- scientific databases
	- gget - quick bioinformatics database lookups
	- alphafold-database
	- bioservices
	- biorxiv-database
	- brenda-database
	- chembl-database
	- clinicaltrials-database
	- clinpgx-database
	- clinvar-database
	- cosmic-database
	- drugbank-database
	- ena-database
	- ensembl-database
	- fda-database
	- gene-database
	- geo-database
	- gwas-database
	- hmdb-database
	- kegg-database
	- pdb-database
	- pubchem-database
	- pubmed-database
	- reactome-database
	- string-database
	- uniprot-database
	- zinc-database
- bioinformatics-cheminformatics skills
	- adme-property-predictor
	- antibody-humanizer
	- datamol
	- deepchem
	- diffdock
	- go-kegg-enrichment
	- gtars
	- medchem
	- molfeat

Many of these are available at https://github.com/K-Dense-AI/scientific-agent-skills if not installed.
