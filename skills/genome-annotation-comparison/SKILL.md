---
name: genome-annotation-comparison
description: Compare Ensembl vs NCBI RefSeq genome annotations (GTF) for the same assembly accession pair (GCA_.../GCF_...). Resolves the correct files directly from the accessions, computes gene/transcript/exon statistics, biotype composition (protein-coding, lncRNA, pseudogene, small RNA classes), isoform complexity, chromosome/scaffold coverage, and cross-matches genes by coordinate overlap to flag biotype disagreements. Use when comparing annotation providers/pipelines for the same genome, auditing wha---
name: genome-annotation-comparison
description: Compare Ensembl vs NCBI RefSeq genome annotations (GTF) for the same assembly accession pair (GCA_.../GCF_...). Resolves the correct files directly from the accessions, computes gene/transcript/exon statistics, biotype composition (protein-coding, lncRNA, pseudogene, small RNA classes), isoform complexity, chromosome/scaffold coverage, and cross-matches genes by coordinate overlap to flag biotype disagreements. Use when comparing annotation providers/pipelines for the same genome, auditing what a differential expression or transcriptomics workflow would see differently depending on which GTF/GFF3 was used as reference, or investigating discrepancies between Ensembl and NCBI gene models.
---
# Genome Annotation Comparison: Ensembl vs NCBI RefSeq

Quantifies how two annotation providers (Ensembl, NCBI RefSeq) differ for
the *same* genome assembly — same coordinates, different gene-calling
pipelines. Useful whenever someone asks "how do the Ensembl and NCBI
annotations for X differ" or needs to understand annotation-source effects
on a differential expression / transcript-quantification pipeline.

## When to use this

- Comparing annotation providers for one organism/assembly.
- Explaining why gene/transcript counts differ between a GTF downloaded
  from Ensembl vs one downloaded from NCBI for what should be "the same"
  genome.
- Auditing biotype composition (how many lncRNA/pseudogene/tRNA genes does
  each source call) before choosing a reference for RNA-seq quantification.
- Checking whether both sources cover the same chromosomes/scaffolds
  (haplotypes, sex chromosomes, organelles, unplaced scaffolds).

## Inputs required

Both a GenBank accession (`GCA_XXXXXXXXX.N`) and its RefSeq counterpart
(`GCF_XXXXXXXXX.N`) for the SAME assembly. These are usually the same
digits with `GCA`→`GCF` and the same version suffix — confirm on the
assembly's NCBI Datasets genome page
(`https://www.ncbi.nlm.nih.gov/datasets/genome/<accession>/`) if unsure. If
the user gives only one accession or a species name, resolve the pair via
`search_skills`/`web_search` or the NCBI Datasets page before starting.

**Gotcha:** for the major community reference assemblies the version
suffixes DIVERGE because the RefSeq copy is re-released independently of
GenBank — e.g. mouse GRCm39 is `GCA_000001635.9` (Ensembl) but
`GCF_000001635.27` (NCBI), and the pair does NOT match digit-for-digit
after the dot. Do not "correct" a mismatched suffix by hand; resolve both
from the assembly page.

## Workflow

1. **Run the pipeline** (needs `requests`, `pandas`, `numpy` — install if
   missing):

   ```python
   result = compare_annotations("GCA_016772045.2", "GCF_016772045.2", workdir="data")
   ```

   This downloads both GTFs + the NCBI assembly report (skips re-download
   if files already exist in `workdir`), parses them, and returns a dict:
   - `result["ensembl"]` / `result["ncbi"]`: each `{genes, transcripts,
     exons, label}` — pandas DataFrames. `genes` has a `biotype_norm`
     column (shared category across providers — see below) and, after the
     pipeline runs, a `fate_vs_other` column (`concordant` / `discordant` /
     `unique`, see step 3).
   - `result["ensembl_stats"]` / `result["ncbi_stats"]`: dicts with
     `n_genes`, `n_transcripts`, `n_exons`, `biotype_counts`,
     `transcripts_per_gene_mean/median/max`,
     `exons_per_transcript_mean/median`.
   - `result["overlap_pairs"]`: DataFrame of `(a_idx, b_idx)` — every
     Ensembl-gene-index / NCBI-gene-index pair whose intervals overlap.
   - `result["chrom_map"]`: RefSeq accession → Ensembl seqid, for reading
     `result["ncbi"]["genes"]["chrom_unified"]` alongside Ensembl's native
     names.

   If `resolve_ensembl` raises `FileNotFoundError`, that organism likely
   has no Ensembl gene build yet — say so rather than guessing a path.
   Ensembl's REST API intermittently 500s under normal load; retry/backoff
   is already built into `resolve_ensembl`, so a raised error there is a
   real absence, not a transient blip.

2. **Report top-level stats** — gene/transcript/exon counts side by side,
   and `biotype_counts` for both sources normalized to the same category
   set (`protein_coding`, `lncRNA`, `pseudogene`, `miRNA`, `snRNA`,
   `snoRNA`, `rRNA`, `tRNA`, `IG_TR_segment`, `other_ncRNA`). Large gaps in
   `lncRNA`/`pseudogene`/`tRNA` between providers are common and usually
   reflect real pipeline differences (e.g. NCBI's Gnomon annotates far more
   pseudogenes and nuclear tRNAs than many Ensembl vertebrate builds,
   which often omit nuclear tRNA loci entirely).

   **Integer-table rule:** tables of integer-valued quantities (gene/
   transcript/exon counts) must never show decimal points. A pandas
   DataFrame column mixing ints and floats is coerced to float and renders
   counts as `78348.0`. Format cells before display — e.g.
   `fmt = lambda v: f"{v:,}" if float(v).is_integer() else f"{v:,.2f}"` —
   and cast numpy integers (`int(...)`) explicitly.

3. **Cross-match genes** to quantify concordance:

   ```python
   pairs = result["overlap_pairs"]
   ens_genes = result["ensembl"]["genes"]
   ens_genes["fate_vs_other"].value_counts()   # concordant / discordant / unique
   ```

   `concordant` = overlaps a same-biotype gene in the other source;
   `discordant` = overlaps the other source's genes but with a *different*
   biotype (e.g. Ensembl calls it lncRNA, NCBI calls it protein_coding —
   this is the class most relevant to differential expression, since reads
   from the same locus get assigned to biologically different "genes"
   depending on which reference was used); `unique` = no overlap at all
   (annotated by only one provider). Filter to `overlap_frac > 0.5` (see
   `annotation_compare.qmd` for the calculation) to exclude incidental
   nested-gene overlaps (e.g. a small ncRNA sitting in a large gene's
   intron) before reporting "disagreements."

4. **Draw at least one worked-example locus as an actual gene-model
   diagram, not just an ID table.** A table of `ens_gene_id`/`ncbi_gene_id`
   pairs tells the reader THAT two providers disagree; a scaled diagram of
   the real exon/intron structure — the "genome browser" style panel —
   shows WHAT the disagreement looks like, and is the more convincing half
   of the worked-examples section. This is a REQUIRED part of the report,
   not optional polish: produce (a) one region-level diagram (Ensembl gene
   calls vs NCBI gene calls, stacked, sharing an x-axis, colored by
   biotype) at a locus where they disagree, and (b) one gene-level isoform
   diagram (every transcript model of one matched protein-coding gene, one
   provider per track) at a locus where transcript structure differs. Pick
   both loci FROM THE DATA, not by hand — the helper code below select a
   real, organism-appropriate example automatically:

   ```python
   region = pick_example_region_locus(result)   # e.g. an NCBI gene with several
                                                  # nested/disagreeing Ensembl calls
   if region:
       plot_region_comparison(
           region["ens_region"], region["ncbi_region"],
           result["ensembl"]["transcripts"], result["ensembl"]["exons"],
           result["ncbi"]["transcripts"], result["ncbi"]["exons"],
           region["xmin"], region["xmax"], chrom_label=f"Chromosome {region['chrom_ens']}",
           ens_release_label=result["ensembl_source"]["release"],
           ncbi_release_label=result["ncbi_source"]["release"],
           suptitle=f"{region['ncbi_gene_id']} locus: nested/disagreeing gene calls",
           savepath="region_example.png",
       )

   isoform = pick_example_isoform_locus(result)  # a matched protein-coding gene with a
                                                   # modest, differing transcript count
   if isoform:
       plot_isoform_comparison(
           isoform["ens_gene_id"], isoform["ncbi_gene_id"],
           isoform["ens_gene_row"], isoform["ncbi_gene_row"],
           result["ensembl"]["transcripts"], result["ensembl"]["exons"],
           result["ncbi"]["transcripts"], result["ncbi"]["exons"],
           ens_label="Ensembl", ncbi_label="NCBI RefSeq",
           chrom_label=f"Chromosome {isoform['ens_gene_row'].seqid}",
           suptitle=f"{isoform['ens_gene_id']}/{isoform['ncbi_gene_id']}: "
                    f"{isoform['ens_ntx']} vs {isoform['ncbi_ntx']} transcript models",
           savepath="isoform_example.png",
       )
   ```

   Both pickers return `None` if no locus in the requested size range exists
   for this organism (rare, but possible for small/sparse genomes) — in that
   case, relax the picker's `min_cluster`/`max_cluster` (region) or
   `min_tx`/`max_tx` (isoform) bounds rather than skipping the figure
   silently. See `helpers.py`'s docstrings for the full parameter list.

5. **Check chromosome/scaffold coverage** by comparing
   `result["ensembl"]["genes"]["seqid"].unique()` against
   `result["ncbi"]["genes"]["seqid"].map(result["chrom_map"])` — a mismatch
   here (a haplotype, sex chromosome, or organelle annotated by one source
   and not the other) is usually a bigger practical problem for RNA-seq
   than any biotype disagreement, and easy to miss if you only look at
   totals.

6. **Compute isoform complexity for matched genes**: restrict
   `overlap_pairs` to `biotype_norm == "protein_coding"` on both sides with
   `overlap_frac > 0.8`, dedupe to a 1:1 best match, then compare
   transcript counts per gene between sources. NCBI's Gnomon pipeline
   applies a documented hard cap of 50 transcript variants per gene; genes
   that hit exactly 50 are capped, not exhaustively modeled.

7. **Visualize** (only when producing a final deliverable — load
   `figure-style` first): a log-scale dumbbell/point plot of gene counts
   by biotype (do NOT use filled bars on a log axis), a stacked bar of
   `fate_vs_other` composition per biotype, AND the two worked-example
   locus diagrams from step 4 (region-level and isoform-level). See
   `annotation_compare.qmd` for a complete, copy-paste example of all
   four.

8. **The deliverable report is `annotation_compare.qmd` RENDERED TO HTML,
   not a markdown/chat writeup.** The qmd (bundled with this skill) is a
   Quarto document, parameterized by `gca_accession`/`gcf_accession`/
   `workdir`, that reproduces the whole analysis end to end — tables,
   figures, worked examples, all six sections (Overview, Gene biotype
   composition, Isoform complexity, Chromosome/scaffold coverage, Worked
   examples, Practical implications) — for any organism pair. Producing a
   comparison report means running this qmd through Quarto and handing the
   user the resulting self-contained `.html` artifact, e.g.:

   ```bash
   quarto render annotation_compare.qmd \
     -P gca_accession:GCA_XXXXXXXXX.N -P gcf_accession:GCF_XXXXXXXXX.N \
     -P workdir:data -o <organism>_annotation_comparison.html
   ```

   To re-run for a new organism, only the two `-P` accessions (and the
   output filename) change — nothing in the qmd itself needs editing. This
   requires `papermill` in the render environment (`-P` param injection
   fails without it: "papermill package is required for
   --execute-params") and `jupyter-cache` (the qmd sets `execute: cache:
   true`; without it Quarto errors "jupyter-cache package is required for
   cached execution"). An environment with `quarto, jupyter, pandas,
   numpy, matplotlib` (e.g. one created via `manage_environments` with
   those seeds) plus those two extras via `manage_packages` is enough.

   **Known sandbox failure modes when running `quarto render` from this
   platform's `bash`/`python` tools, in the order you'll hit them, with
   the fix for each:**
   - `PermissionDenied: ... stat '/Users/<user>/Library/Caches/quarto'` —
     the sandbox blocks the real `$HOME/Library`. Fix: point `HOME` at a
     writable scratch dir for the render subprocess only, e.g.
     `HOME=/tmp/qhome quarto render ...` (create `/tmp/qhome` first).
   - `ModuleNotFoundError: No module named 'log'` from
     `quarto_cli/share/jupyter/jupyter.py` — this platform's kernels
     export `PYTHONSAFEPATH=1`, which stops Python from adding a directly-
     invoked script's own directory to `sys.path`, so Quarto's Jupyter
     bridge script can't find its sibling `log.py`. Fix: `unset
     PYTHONSAFEPATH` before invoking `quarto render` (do this in the same
     shell command/cell — it only needs to be absent for the quarto
     subprocess).
   - `The jupyter-cache package is required for cached execution` /
     `The papermill package is required for processing --execute-params`
     — install the missing one with `manage_packages` into the render
     environment and retry.
   - `PermissionError: [Errno 1] Operation not permitted` inside
     `jupyter_client...find_available_port` / `tmp_sock.bind((ip, 0))` —
     the sandbox denies the `bind()` syscall entirely, even on loopback,
     which the Jupyter kernel manager needs to open its ZMQ comm ports.
     **This one has no known local fix** — it's an OS-level sandbox
     restriction on this platform's `bash`/`python`/`r` tools, not a
     Quarto or environment misconfiguration. If a genuinely unsandboxed
     target is available (a `list_compute` SSH/HPC host with `quarto`
     installed or installable), rendering there works around it; otherwise
     use the fallback below.

   **Known Quarto quirks (validated on Quarto 1.3.306), in the order you'll
   hit them when re-rendering for a new organism:**
   - *`-P` params are silently NOT injected into Jupyter kernels on Quarto
     <1.4* (and neither are YAML `params:`). The qmd falls back to its
     default accessions and renders the WRONG ORGANISM — worse, with a
     shared `workdir` the fallback run silently reuses the cached GTFs of
     the intended organism under the default accessions' labels. Always
     grep the rendered HTML for the expected accession string before
     trusting it. On Quarto <1.4, edit the defaults in the YAML front-matter
     AND the setup-cell fallbacks; `quarto render -P ...` only works on
     ≥1.4.
   - *A `#| label: tbl-*` cell without `#| tbl-cap:` renders its caption
     as a literal "?(caption)" placeholder* (same for `fig-*` without
     `fig-cap:`). Every crossreference-labeled cell must carry a caption.
   - *A cell whose last expression is a matplotlib `Figure` object gets
     split into subfigures on Quarto <1.4* — the figure appears TWICE and
     its caption breaks. End figure cells with `plt.show()` instead.
   - *Inline `` `r ...` `` code never executes in a Jupyter qmd* (knitr
     only) and renders literally. Use a `display(Markdown(...))` cell for
     computed prose.
   - *Stale `jupyter-cache` executions are reused silently* — after
     changing params or fixing a cell, delete `.jupyter_cache/` before
     re-rendering, or the previous (possibly wrong-organism) outputs come
     back.
   - *The pickled pipeline result for a mammal-sized genome is ~1 GB; a
     truncated write fails later with `UnpicklingError: pickle data was
     truncated`.* Write it with `fh.flush(); os.fsync(fh.fileno())` and
     round-trip-verify the pickle right after writing it.

   **Fallback when the socket-bind block can't be worked around:** hand-
   assemble a static HTML file that mirrors the qmd's structure exactly —
   same section order and headings (Overview / Gene biotype composition /
   Isoform complexity / Chromosome-scaffold coverage / Worked examples /
   Practical implications), the same tables (rendered with
   `DataFrame.to_html(classes="data-table")`), and the same two figures
   embedded inline as base64 PNGs (`<img
   src="data:image/png;base64,...">`) so the file is self-contained like
   Quarto's `embed-resources: true` output — not a bare markdown dump of
   numbers. Compute every number from `compare_annotations(...)`'s actual
   return value; never hand-type a figure from a prior run into the
   template. This produces a report indistinguishable in content and
   structure from a true Quarto render, and is the expected deliverable
   whenever `quarto render` itself can't complete in the current
   environment.

## Biotype normalization reference

Ensembl and NCBI RefSeq use different biotype vocabularies for the same
concepts. `normalize_biotype()` maps both onto one set:

| Category | Ensembl terms | NCBI RefSeq terms |
|---|---|---|
| protein_coding | protein_coding | protein_coding |
| lncRNA | lncRNA | lncRNA |
| pseudogene | pseudogene, processed_pseudogene | pseudogene, transcribed_pseudogene |
| miRNA | miRNA | miRNA |
| snRNA | snRNA | snRNA |
| snoRNA | snoRNA | snoRNA |
| rRNA | rRNA, Mt_rRNA | rRNA |
| tRNA | Mt_tRNA (rarely nuclear tRNA) | tRNA |
| IG_TR_segment | IG_V/C/D/J_gene, TR_V/J/C/D_gene | V_segment, C_region |
| other_ncRNA | misc_RNA, Y_RNA, vault_RNA, ribozyme, scaRNA | misc_RNA, ncRNA |

## Files bundled with this skill

- `helpers.py` — auto-loaded helper functions (see Workflow above).
- `annotation_compare.qmd` — parameterized Quarto notebook for a
  standalone, repeatable report.
t a differential expression or transcriptomics workflow would see differently depending on which GTF/GFF3 was used as reference, or investigating discrepancies between Ensembl and NCBI gene models.
---
# Genome Annotation Comparison: Ensembl vs NCBI RefSeq

Quantifies how two annotation providers (Ensembl, NCBI RefSeq) differ for
the *same* genome assembly — same coordinates, different gene-calling
pipelines. Useful whenever someone asks "how do the Ensembl and NCBI
annotations for X differ" or needs to understand annotation-source effects
on a differential expression / transcript-quantification pipeline.

## When to use this

- Comparing annotation providers for one organism/assembly.
- Explaining why gene/transcript counts differ between a GTF downloaded
  from Ensembl vs one downloaded from NCBI for what should be "the same"
  genome.
- Auditing biotype composition (how many lncRNA/pseudogene/tRNA genes does
  each source call) before choosing a reference for RNA-seq quantification.
- Checking whether both sources cover the same chromosomes/scaffolds
  (haplotypes, sex chromosomes, organelles, unplaced scaffolds).

## Inputs required

Both a GenBank accession (`GCA_XXXXXXXXX.N`) and its RefSeq counterpart
(`GCF_XXXXXXXXX.N`) for the SAME assembly. These are usually the same
digits with `GCA`→`GCF` and the same version suffix — confirm on the
assembly's NCBI Datasets genome page
(`https://www.ncbi.nlm.nih.gov/datasets/genome/<accession>/`) if unsure. If
the user gives only one accession or a species name, resolve the pair via
`search_skills`/`web_search` or the NCBI Datasets page before starting.

## Workflow

1. **Run the pipeline** (needs `requests`, `pandas`, `numpy` — install if
   missing):

   ```python
   result = compare_annotations("GCA_016772045.2", "GCF_016772045.2", workdir="data")
   ```

   This downloads both GTFs + the NCBI assembly report (skips re-download
   if files already exist in `workdir`), parses them, and returns a dict:
   - `result["ensembl"]` / `result["ncbi"]`: each `{genes, transcripts,
     exons, label}` — pandas DataFrames. `genes` has a `biotype_norm`
     column (shared category across providers — see below) and, after the
     pipeline runs, a `fate_vs_other` column (`concordant` / `discordant` /
     `unique`, see step 3).
   - `result["ensembl_stats"]` / `result["ncbi_stats"]`: dicts with
     `n_genes`, `n_transcripts`, `n_exons`, `biotype_counts`,
     `transcripts_per_gene_mean/median/max`,
     `exons_per_transcript_mean/median`.
   - `result["overlap_pairs"]`: DataFrame of `(a_idx, b_idx)` — every
     Ensembl-gene-index / NCBI-gene-index pair whose intervals overlap.
   - `result["chrom_map"]`: RefSeq accession → Ensembl seqid, for reading
     `result["ncbi"]["genes"]["chrom_unified"]` alongside Ensembl's native
     names.

   If `resolve_ensembl` raises `FileNotFoundError`, that organism likely
   has no Ensembl gene build yet — say so rather than guessing a path.
   Ensembl's REST API intermittently 500s under normal load; retry/backoff
   is already built into `resolve_ensembl`, so a raised error there is a
   real absence, not a transient blip.

2. **Report top-level stats** — gene/transcript/exon counts side by side,
   and `biotype_counts` for both sources normalized to the same category
   set (`protein_coding`, `lncRNA`, `pseudogene`, `miRNA`, `snRNA`,
   `snoRNA`, `rRNA`, `tRNA`, `IG_TR_segment`, `other_ncRNA`). Large gaps in
   `lncRNA`/`pseudogene`/`tRNA` between providers are common and usually
   reflect real pipeline differences (e.g. NCBI's Gnomon annotates far more
   pseudogenes and nuclear tRNAs than many Ensembl vertebrate builds,
   which often omit nuclear tRNA loci entirely).

3. **Cross-match genes** to quantify concordance:

   ```python
   pairs = result["overlap_pairs"]
   ens_genes = result["ensembl"]["genes"]
   ens_genes["fate_vs_other"].value_counts()   # concordant / discordant / unique
   ```

   `concordant` = overlaps a same-biotype gene in the other source;
   `discordant` = overlaps the other source's genes but with a *different*
   biotype (e.g. Ensembl calls it lncRNA, NCBI calls it protein_coding —
   this is the class most relevant to differential expression, since reads
   from the same locus get assigned to biologically different "genes"
   depending on which reference was used); `unique` = no overlap at all
   (annotated by only one provider). Filter to `overlap_frac > 0.5` (see
   `annotation_compare.qmd` for the calculation) to exclude incidental
   nested-gene overlaps (e.g. a small ncRNA sitting in a large gene's
   intron) before reporting "disagreements."

4. **Draw at least one worked-example locus as an actual gene-model
   diagram, not just an ID table.** A table of `ens_gene_id`/`ncbi_gene_id`
   pairs tells the reader THAT two providers disagree; a scaled diagram of
   the real exon/intron structure — the "genome browser" style panel —
   shows WHAT the disagreement looks like, and is the more convincing half
   of the worked-examples section. This is a REQUIRED part of the report,
   not optional polish: produce (a) one region-level diagram (Ensembl gene
   calls vs NCBI gene calls, stacked, sharing an x-axis, colored by
   biotype) at a locus where they disagree, and (b) one gene-level isoform
   diagram (every transcript model of one matched protein-coding gene, one
   provider per track) at a locus where transcript structure differs. Pick
   both loci FROM THE DATA, not by hand — the kernel helpers below select a
   real, organism-appropriate example automatically:

   ```python
   region = pick_example_region_locus(result)   # e.g. an NCBI gene with several
                                                  # nested/disagreeing Ensembl calls
   if region:
       plot_region_comparison(
           region["ens_region"], region["ncbi_region"],
           result["ensembl"]["transcripts"], result["ensembl"]["exons"],
           result["ncbi"]["transcripts"], result["ncbi"]["exons"],
           region["xmin"], region["xmax"], chrom_label=f"Chromosome {region['chrom_ens']}",
           ens_release_label=result["ensembl_source"]["release"],
           ncbi_release_label=result["ncbi_source"]["release"],
           suptitle=f"{region['ncbi_gene_id']} locus: nested/disagreeing gene calls",
           savepath="region_example.png",
       )

   isoform = pick_example_isoform_locus(result)  # a matched protein-coding gene with a
                                                   # modest, differing transcript count
   if isoform:
       plot_isoform_comparison(
           isoform["ens_gene_id"], isoform["ncbi_gene_id"],
           isoform["ens_gene_row"], isoform["ncbi_gene_row"],
           result["ensembl"]["transcripts"], result["ensembl"]["exons"],
           result["ncbi"]["transcripts"], result["ncbi"]["exons"],
           ens_label="Ensembl", ncbi_label="NCBI RefSeq",
           chrom_label=f"Chromosome {isoform['ens_gene_row'].seqid}",
           suptitle=f"{isoform['ens_gene_id']}/{isoform['ncbi_gene_id']}: "
                    f"{isoform['ens_ntx']} vs {isoform['ncbi_ntx']} transcript models",
           savepath="isoform_example.png",
       )
   ```

   Both pickers return `None` if no locus in the requested size range exists
   for this organism (rare, but possible for small/sparse genomes) — in that
   case, relax the picker's `min_cluster`/`max_cluster` (region) or
   `min_tx`/`max_tx` (isoform) bounds rather than skipping the figure
   silently. See `kernel.py`'s docstrings for the full parameter list.

5. **Check chromosome/scaffold coverage** by comparing
   `result["ensembl"]["genes"]["seqid"].unique()` against
   `result["ncbi"]["genes"]["seqid"].map(result["chrom_map"])` — a mismatch
   here (a haplotype, sex chromosome, or organelle annotated by one source
   and not the other) is usually a bigger practical problem for RNA-seq
   than any biotype disagreement, and easy to miss if you only look at
   totals.

6. **Compute isoform complexity for matched genes**: restrict
   `overlap_pairs` to `biotype_norm == "protein_coding"` on both sides with
   `overlap_frac > 0.8`, dedupe to a 1:1 best match, then compare
   transcript counts per gene between sources. NCBI's Gnomon pipeline
   applies a documented hard cap of 50 transcript variants per gene; genes
   that hit exactly 50 are capped, not exhaustively modeled.

7. **Visualize** (only when producing a final deliverable — load
   `figure-style` first): a log-scale dumbbell/point plot of gene counts
   by biotype (do NOT use filled bars on a log axis), a stacked bar of
   `fate_vs_other` composition per biotype, AND the two worked-example
   locus diagrams from step 4 (region-level and isoform-level). See
   `annotation_compare.qmd` for a complete, copy-paste example of all
   four.

8. **The deliverable report is `annotation_compare.qmd` RENDERED TO HTML,
   not a markdown/chat writeup.** The qmd (bundled with this skill) is a
   Quarto document, parameterized by `gca_accession`/`gcf_accession`/
   `workdir`, that reproduces the whole analysis end to end — tables,
   figures, worked examples, all six sections (Overview, Gene biotype
   composition, Isoform complexity, Chromosome/scaffold coverage, Worked
   examples, Practical implications) — for any organism pair. Producing a
   comparison report means running this qmd through Quarto and handing the
   user the resulting self-contained `.html` artifact, e.g.:

   ```bash
   quarto render annotation_compare.qmd \
     -P gca_accession:GCA_XXXXXXXXX.N -P gcf_accession:GCF_XXXXXXXXX.N \
     -P workdir:data -o <organism>_annotation_comparison.html
   ```

   To re-run for a new organism, only the two `-P` accessions (and the
   output filename) change — nothing in the qmd itself needs editing. This
   requires `papermill` in the render environment (`-P` param injection
   fails without it: "papermill package is required for
   --execute-params") and `jupyter-cache` (the qmd sets `execute: cache:
   true`; without it Quarto errors "jupyter-cache package is required for
   cached execution"). An environment with `quarto, jupyter, pandas,
   numpy, matplotlib` (e.g. one created via `manage_environments` with
   those seeds) plus those two extras via `manage_packages` is enough.

   **Known sandbox failure modes when running `quarto render` from this
   platform's `bash`/`python` tools, in the order you'll hit them, with
   the fix for each:**
   - `PermissionDenied: ... stat '/Users/<user>/Library/Caches/quarto'` —
     the sandbox blocks the real `$HOME/Library`. Fix: point `HOME` at a
     writable scratch dir for the render subprocess only, e.g.
     `HOME=/tmp/qhome quarto render ...` (create `/tmp/qhome` first).
   - `ModuleNotFoundError: No module named 'log'` from
     `quarto_cli/share/jupyter/jupyter.py` — this platform's kernels
     export `PYTHONSAFEPATH=1`, which stops Python from adding a directly-
     invoked script's own directory to `sys.path`, so Quarto's Jupyter
     bridge script can't find its sibling `log.py`. Fix: `unset
     PYTHONSAFEPATH` before invoking `quarto render` (do this in the same
     shell command/cell — it only needs to be absent for the quarto
     subprocess).
   - `The jupyter-cache package is required for cached execution` /
     `The papermill package is required for processing --execute-params`
     — install the missing one with `manage_packages` into the render
     environment and retry.
   - `PermissionError: [Errno 1] Operation not permitted` inside
     `jupyter_client...find_available_port` / `tmp_sock.bind((ip, 0))` —
     the sandbox denies the `bind()` syscall entirely, even on loopback,
     which the Jupyter kernel manager needs to open its ZMQ comm ports.
     **This one has no known local fix** — it's an OS-level sandbox
     restriction on this platform's `bash`/`python`/`r` tools, not a
     Quarto or environment misconfiguration. If a genuinely unsandboxed
     target is available (a `list_compute` SSH/HPC host with `quarto`
     installed or installable), rendering there works around it; otherwise
     use the fallback below.

   **Fallback when the socket-bind block can't be worked around:** hand-
   assemble a static HTML file that mirrors the qmd's structure exactly —
   same section order and headings (Overview / Gene biotype composition /
   Isoform complexity / Chromosome-scaffold coverage / Worked examples /
   Practical implications), the same tables (rendered with
   `DataFrame.to_html(classes="data-table")`), and the same two figures
   embedded inline as base64 PNGs (`<img
   src="data:image/png;base64,...">`) so the file is self-contained like
   Quarto's `embed-resources: true` output — not a bare markdown dump of
   numbers. Compute every number from `compare_annotations(...)`'s actual
   return value; never hand-type a figure from a prior run into the
   template. This produces a report indistinguishable in content and
   structure from a true Quarto render, and is the expected deliverable
   whenever `quarto render` itself can't complete in the current
   environment.

## Biotype normalization reference

Ensembl and NCBI RefSeq use different biotype vocabularies for the same
concepts. `normalize_biotype()` maps both onto one set:

| Category | Ensembl terms | NCBI RefSeq terms |
|---|---|---|
| protein_coding | protein_coding | protein_coding |
| lncRNA | lncRNA | lncRNA |
| pseudogene | pseudogene, processed_pseudogene | pseudogene, transcribed_pseudogene |
| miRNA | miRNA | miRNA |
| snRNA | snRNA | snRNA |
| snoRNA | snoRNA | snoRNA |
| rRNA | rRNA, Mt_rRNA | rRNA |
| tRNA | Mt_tRNA (rarely nuclear tRNA) | tRNA |
| IG_TR_segment | IG_V/C/D/J_gene, TR_V/J/C/D_gene | V_segment, C_region |
| other_ncRNA | misc_RNA, Y_RNA, vault_RNA, ribozyme, scaRNA | misc_RNA, ncRNA |

## Files bundled with this skill

- `kernel.py` — auto-loaded helper functions (see Workflow above).
- `annotation_compare.qmd` — parameterized Quarto notebook for a
  standalone, repeatable report.
