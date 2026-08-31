"""
Reusable helpers for comparing Ensembl vs NCBI RefSeq genome annotations
(GTF) for the same assembly. See SKILL.md for the full workflow.

Call `compare_annotations(gca_accession, gcf_accession, workdir=...)` for the
end-to-end pipeline, or use the individual functions to customize a step.
"""
import gzip
import io
import os
import re
import time

import numpy as np
import pandas as pd

ENSEMBL_REST = "https://rest.ensembl.org"
ENSEMBL_FTP = "https://ftp.ensembl.org/pub"
NCBI_FTP = "https://ftp.ncbi.nlm.nih.gov/genomes/all"

GTF_ATTR_KEYS = [
    "gene_id", "gene_name", "gene_biotype", "transcript_id",
    "transcript_biotype", "exon_number", "db_xref",
]

BIOTYPE_NORMALIZATION = {
    "protein_coding": "protein_coding",
    "lncRNA": "lncRNA",
    "pseudogene": "pseudogene",
    "processed_pseudogene": "pseudogene",
    "transcribed_pseudogene": "pseudogene",
    "unitary_pseudogene": "pseudogene",
    "unprocessed_pseudogene": "pseudogene",
    "miRNA": "miRNA",
    "snRNA": "snRNA",
    "snoRNA": "snoRNA",
    "rRNA": "rRNA",
    "Mt_rRNA": "rRNA",
    "tRNA": "tRNA",
    "Mt_tRNA": "tRNA",
    "misc_RNA": "other_ncRNA",
    "ncRNA": "other_ncRNA",
    "Y_RNA": "other_ncRNA",
    "vault_RNA": "other_ncRNA",
    "ribozyme": "other_ncRNA",
    "scaRNA": "other_ncRNA",
    "TR_V_gene": "IG_TR_segment",
    "TR_J_gene": "IG_TR_segment",
    "TR_C_gene": "IG_TR_segment",
    "TR_D_gene": "IG_TR_segment",
    "IG_V_gene": "IG_TR_segment",
    "IG_C_gene": "IG_TR_segment",
    "IG_D_gene": "IG_TR_segment",
    "IG_J_gene": "IG_TR_segment",
    "V_segment": "IG_TR_segment",
    "C_region": "IG_TR_segment",
    "J_segment": "IG_TR_segment",
    "D_segment": "IG_TR_segment",
}


def normalize_biotype(biotype):
    """Map a provider-specific gene_biotype string to a shared category."""
    if biotype is None:
        return "other"
    return BIOTYPE_NORMALIZATION.get(biotype, "other")


def http_get_with_retry(url, tries=5, backoff=3.0, **kwargs):
    """Ensembl's REST API intermittently 500s under no apparent load; a
    short retry-with-backoff clears it almost every time."""
    import requests
    last_exc = None
    for attempt in range(tries):
        try:
            r = requests.get(url, timeout=30, **kwargs)
            if r.status_code == 200:
                return r
            last_exc = requests.exceptions.HTTPError(f"{r.status_code} for {url}")
        except requests.exceptions.RequestException as exc:
            last_exc = exc
        time.sleep(backoff * (attempt + 1))
    raise last_exc


def resolve_ensembl(gca_accession):
    """Resolve the Ensembl (vertebrates) GTF/GFF3 URLs for a GCA accession.

    Returns a dict: {provider, species, assembly_name, release, gtf_url,
    gff3_url}. Raises FileNotFoundError if no Ensembl gene build exists for
    this assembly (main-site release or Rapid Release).
    """
    r = http_get_with_retry(f"{ENSEMBL_REST}/info/genomes/assembly/{gca_accession}",
                              params={"content-type": "application/json"})
    info = r.json()
    species_prod_name = info["name"]
    url_name = info.get("url_name", species_prod_name.capitalize())
    assembly_default = info["assembly_default"]

    idx = http_get_with_retry(f"{ENSEMBL_FTP}/").text
    releases = sorted({int(m) for m in re.findall(r"release-(\d+)/", idx)}, reverse=True)

    import requests
    for rel in releases:
        gtf_url = f"{ENSEMBL_FTP}/release-{rel}/gtf/{species_prod_name}/{url_name}.{assembly_default}.{rel}.gtf.gz"
        gff3_url = f"{ENSEMBL_FTP}/release-{rel}/gff3/{species_prod_name}/{url_name}.{assembly_default}.{rel}.gff3.gz"
        head = requests.head(gtf_url, timeout=30)
        if head.status_code == 200:
            return {"provider": "ensembl", "species": species_prod_name,
                    "assembly_name": assembly_default, "release": str(rel),
                    "gtf_url": gtf_url, "gff3_url": gff3_url}

    rapid_dir = f"{ENSEMBL_FTP}/rapid-release/species/{url_name}/{gca_accession}/"
    rr = requests.get(rapid_dir, timeout=30)
    if rr.status_code == 200:
        files = re.findall(r'href="([^"]+\.gtf\.gz)"', rr.text)
        gff_files = re.findall(r'href="([^"]+\.gff3\.gz)"', rr.text)
        if files:
            return {"provider": "ensembl", "species": species_prod_name,
                     "assembly_name": assembly_default, "release": "rapid",
                     "gtf_url": rapid_dir + files[0],
                     "gff3_url": (rapid_dir + gff_files[0]) if gff_files else ""}

    raise FileNotFoundError(
        f"Could not locate an Ensembl GTF for {gca_accession} "
        f"(species={species_prod_name}, assembly={assembly_default}) "
        f"on main-site releases {releases[:3]}... or rapid-release."
    )


def resolve_ncbi(gcf_accession):
    """Resolve the NCBI RefSeq GTF/GFF3/assembly-report URLs for a GCF accession."""
    import requests
    m = re.match(r"GCF_(\d{3})(\d{3})(\d{3})\.\d+", gcf_accession)
    if not m:
        raise ValueError(f"'{gcf_accession}' does not look like a GCF_XXXXXXXXX.N accession")
    triplet_dir = f"{NCBI_FTP}/GCF/{m.group(1)}/{m.group(2)}/{m.group(3)}/"
    idx = requests.get(triplet_dir, timeout=30)
    idx.raise_for_status()
    subdirs = re.findall(rf'href="({re.escape(gcf_accession)}_[^"/]+)/"', idx.text)
    if not subdirs:
        raise FileNotFoundError(f"No assembly directory found under {triplet_dir} for {gcf_accession}")
    asm_dir_name = subdirs[0]
    base = f"{triplet_dir}{asm_dir_name}/"
    assembly_name = asm_dir_name.split("_", 2)[-1]
    return {"provider": "ncbi", "assembly_name": assembly_name, "release": asm_dir_name,
            "gtf_url": f"{base}{asm_dir_name}_genomic.gtf.gz",
            "gff3_url": f"{base}{asm_dir_name}_genomic.gff.gz",
            "assembly_report_url": f"{base}{asm_dir_name}_assembly_report.txt"}


def download(url, dest, overwrite=False):
    import requests
    if os.path.exists(dest) and not overwrite and os.path.getsize(dest) > 0:
        return dest
    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    tmp = dest + ".part"
    with requests.get(url, stream=True, timeout=120) as r:
        r.raise_for_status()
        with open(tmp, "wb") as f:
            for chunk in r.iter_content(chunk_size=1 << 20):
                f.write(chunk)
    os.replace(tmp, dest)
    return dest


def parse_gtf(path, attr_keys=None):
    """Parse a (gzipped) GTF into a flat DataFrame, one row per feature line."""
    if attr_keys is None:
        attr_keys = GTF_ATTR_KEYS
    rows = []
    opener = gzip.open if path.endswith(".gz") else open
    attr_re = re.compile(r'(\w+)\s+"([^"]*)"')
    with opener(path, "rt") as f:
        for line in f:
            if line.startswith("#"):
                continue
            fields = line.rstrip("\n").split("\t")
            if len(fields) != 9:
                continue
            seqid, source, feature, start, end, score, strand, frame, attr_str = fields
            attrs = {}
            for mm in attr_re.finditer(attr_str):
                k, v = mm.group(1), mm.group(2)
                if k in attr_keys:
                    attrs[k] = v
            row = [seqid, source, feature, int(start), int(end), strand] + [attrs.get(k) for k in attr_keys]
            rows.append(row)
    cols = ["seqid", "source", "feature", "start", "end", "strand"] + attr_keys
    return pd.DataFrame(rows, columns=cols)


def parse_ncbi_assembly_report(path):
    with open(path) as f:
        lines = f.readlines()
    header_line = next(l for l in lines if l.startswith("# Sequence-Name"))
    data_lines = [l for l in lines if not l.startswith("#")]
    report = pd.read_csv(io.StringIO(header_line.lstrip("#") + "".join(data_lines)), sep="\t")
    report.columns = [c.strip() for c in report.columns]
    return report


def ensembl_name_for_report_row(row, ensembl_seq_names):
    sn = row["Sequence-Name"]
    gb = row["GenBank-Accn"]
    if isinstance(sn, str) and sn.startswith("scaffold_chr"):
        candidate = sn.replace("scaffold_chr", "")
        if candidate in ensembl_seq_names:
            return candidate
    if sn in ("X", "Y", "MT") and sn in ensembl_seq_names:
        return sn
    if gb != "na" and gb in ensembl_seq_names:
        return gb
    if sn in ensembl_seq_names:
        return sn
    return None


def build_chrom_mapping(report, ensembl_seq_names):
    """RefSeq accession -> the seqid Ensembl uses for the same sequence."""
    report = report.copy()
    report["ensembl_name"] = report.apply(lambda r: ensembl_name_for_report_row(r, ensembl_seq_names), axis=1)
    mapping = dict(zip(report["RefSeq-Accn"], report["ensembl_name"]))
    return {k: v for k, v in mapping.items() if k and k != "na"}


def build_tables(gtf_df, label):
    """Split a parsed GTF DataFrame into gene / transcript / exon tables and
    attach a normalized biotype column to genes."""
    genes = gtf_df[gtf_df.feature == "gene"].copy().reset_index(drop=True)
    genes["biotype_norm"] = genes["gene_biotype"].map(normalize_biotype)
    transcripts = gtf_df[gtf_df.feature == "transcript"].copy().reset_index(drop=True)
    exons = gtf_df[gtf_df.feature == "exon"].copy().reset_index(drop=True)
    return {"genes": genes, "transcripts": transcripts, "exons": exons, "label": label}


def summary_stats(ann):
    tpg = ann["transcripts"].groupby("gene_id").size()
    ept = ann["exons"].groupby("transcript_id").size()
    return {
        "label": ann["label"],
        "n_genes": len(ann["genes"]),
        "n_transcripts": len(ann["transcripts"]),
        "n_exons": len(ann["exons"]),
        "n_chromosomes_scaffolds": ann["genes"]["seqid"].nunique(),
        "biotype_counts": ann["genes"]["biotype_norm"].value_counts().to_dict(),
        "transcripts_per_gene_mean": float(tpg.mean()) if len(tpg) else float("nan"),
        "transcripts_per_gene_median": float(tpg.median()) if len(tpg) else float("nan"),
        "transcripts_per_gene_max": int(tpg.max()) if len(tpg) else 0,
        "exons_per_transcript_mean": float(ept.mean()) if len(ept) else float("nan"),
        "exons_per_transcript_median": float(ept.median()) if len(ept) else float("nan"),
    }


def overlap_pairs(gA, gB, chrom_col="chrom_unified"):
    """All (gA_index, gB_index) pairs whose [start,end] intervals overlap on
    the same unified chromosome/scaffold name. O(n log n) per chromosome."""
    pairs = []
    for chrom, subA in gA.groupby(chrom_col):
        subB = gB[gB[chrom_col] == chrom]
        if len(subB) == 0:
            continue
        b_starts = subB["start"].values
        b_ends = subB["end"].values
        b_idx = subB.index.values
        order = np.argsort(b_starts)
        b_starts_sorted = b_starts[order]
        b_ends_sorted = b_ends[order]
        b_idx_sorted = b_idx[order]
        for a_idx, a_start, a_end in zip(subA.index.values, subA["start"].values, subA["end"].values):
            lo = np.searchsorted(b_starts_sorted, a_end, side="right")
            if lo == 0:
                continue
            cand_ends = b_ends_sorted[:lo]
            hits = np.where(cand_ends >= a_start)[0]
            for h in hits:
                pairs.append((a_idx, b_idx_sorted[:lo][h]))
    return pd.DataFrame(pairs, columns=["a_idx", "b_idx"])


def classify_gene_fates(genes_a, genes_b, pairs):
    """For each gene in genes_a: 'concordant' (overlaps a same-biotype gene
    in genes_b), 'discordant' (overlaps genes_b only with a different
    biotype), or 'unique' (no overlap at all)."""
    b_biotype = genes_b["biotype_norm"]
    by_a = pairs.groupby("a_idx")["b_idx"].apply(list).to_dict()

    def classify(a_idx, biotype):
        b_idxs = by_a.get(a_idx)
        if not b_idxs:
            return "unique"
        bts = b_biotype.loc[b_idxs]
        return "concordant" if (bts == biotype).any() else "discordant"

    return pd.Series(
        [classify(i, b) for i, b in zip(genes_a.index, genes_a["biotype_norm"])],
        index=genes_a.index,
    )


def compare_annotations(gca_accession, gcf_accession, workdir="data", overwrite=False):
    """End-to-end pipeline: download + parse + cross-match Ensembl vs NCBI
    RefSeq annotations for one assembly.

    Returns a dict with keys: ensembl_source, ncbi_source, ensembl, ncbi
    (each {genes, transcripts, exons, label}), assembly_report, chrom_map,
    overlap_pairs, ensembl_stats, ncbi_stats.
    """
    os.makedirs(workdir, exist_ok=True)

    ens_src = resolve_ensembl(gca_accession)
    ncbi_src = resolve_ncbi(gcf_accession)

    ens_gtf_path = download(ens_src["gtf_url"], os.path.join(workdir, "ensembl.gtf.gz"), overwrite)
    ncbi_gtf_path = download(ncbi_src["gtf_url"], os.path.join(workdir, "ncbi.gtf.gz"), overwrite)
    report_path = download(ncbi_src["assembly_report_url"], os.path.join(workdir, "ncbi_assembly_report.txt"), overwrite)

    ens_gtf = parse_gtf(ens_gtf_path)
    ncbi_gtf = parse_gtf(ncbi_gtf_path)
    report = parse_ncbi_assembly_report(report_path)

    ens_ann = build_tables(ens_gtf, label=f"Ensembl ({ens_src['assembly_name']}, release {ens_src['release']})")
    ncbi_ann = build_tables(ncbi_gtf, label=f"NCBI RefSeq ({ncbi_src['release']})")

    ensembl_seq_names = set(ens_ann["genes"]["seqid"].unique()) | set(ens_gtf["seqid"].unique())
    chrom_map = build_chrom_mapping(report, ensembl_seq_names)

    ens_ann["genes"]["chrom_unified"] = ens_ann["genes"]["seqid"]
    ncbi_ann["genes"]["chrom_unified"] = ncbi_ann["genes"]["seqid"].map(chrom_map)

    pairs = overlap_pairs(ens_ann["genes"], ncbi_ann["genes"])
    ens_ann["genes"]["fate_vs_other"] = classify_gene_fates(ens_ann["genes"], ncbi_ann["genes"], pairs)
    ncbi_ann["genes"]["fate_vs_other"] = classify_gene_fates(
        ncbi_ann["genes"], ens_ann["genes"],
        pairs.rename(columns={"a_idx": "b_idx", "b_idx": "a_idx"})[["a_idx", "b_idx"]],
    )

    return {
        "ensembl_source": ens_src, "ncbi_source": ncbi_src,
        "ensembl": ens_ann, "ncbi": ncbi_ann,
        "assembly_report": report, "chrom_map": chrom_map,
        "overlap_pairs": pairs,
        "ensembl_stats": summary_stats(ens_ann),
        "ncbi_stats": summary_stats(ncbi_ann),
    }

# --- Locus-diagram helpers (worked-example figures) ---
#
# A table of gene-ID pairs (see classify_gene_fates / overlap_pairs) tells you
# THAT two providers disagree at a locus; these helpers show WHAT the
# disagreement looks like by drawing the actual gene/transcript models to
# scale, colored by biotype — one panel per provider, sharing an x-axis. Two
# usage patterns:
#   1. `pick_example_region_locus(result)` / `pick_example_isoform_locus(result)`
#      to auto-select an illustrative, real locus from THIS organism's data
#      (no hardcoded gene names — every organism gets its own examples), then
#      `plot_region_comparison(...)` / `plot_isoform_comparison(...)` to draw it.
#   2. Call the plot_* functions directly with a locus you already picked.

LOCUS_BIOTYPE_COLORS = {
    "protein_coding": "#3B7DD8", "lncRNA": "#E07B39", "pseudogene": "#8C8C8C",
    "snRNA": "#4CAF50", "miRNA": "#9B59B6", "snoRNA": "#16A085", "tRNA": "#C0392B",
    "other_ncRNA": "#B0A400", "IG_TR_segment": "#D4527A", "other": "#B0A400",
}
LOCUS_BIOTYPE_DISPLAY = {
    "protein_coding": "Protein-coding", "lncRNA": "lncRNA", "pseudogene": "Pseudogene",
    "snRNA": "snRNA", "miRNA": "miRNA", "snoRNA": "snoRNA", "tRNA": "tRNA",
    "other_ncRNA": "Other ncRNA", "IG_TR_segment": "IG/TR segment", "other": "Other",
}


def set_locus_axis_frame(ax, style="open"):
    """Spine/tick styling for locus-diagram axes (kept separate from any
    figure-style skill's set_frame to avoid a name collision when both are
    loaded)."""
    show = {"open": (False, False, True, True),
            "boxed": (True, True, True, True),
            "none": (False, False, False, False)}[style]
    for side, vis in zip(("top", "right", "bottom", "left"), show):
        ax.spines[side].set_visible(vis)
        if vis:
            ax.spines[side].set_linewidth(0.6)
    ax.tick_params(direction="out", length=0 if style == "none" else 3, width=0.6)


def draw_strand_arrows(ax, x0, x1, y, strand, color, n=3, size=6):
    """Draw small '>' or '<' markers along [x0, x1] at height y to show strand."""
    import numpy as np
    if x1 <= x0:
        return
    xs = np.linspace(x0, x1, n + 2)[1:-1]
    marker = ">" if strand == "+" else "<"
    for x in xs:
        ax.plot(x, y, marker=marker, color=color, markersize=size, zorder=2, linestyle="None")


def draw_gene_model(ax, y, exon_starts, exon_ends, gene_start, gene_end, strand, color,
                     exon_height=0.34, line_width=1.3):
    """Draw one gene/transcript model at row y: a thin intron line across the
    full span, thick exon rectangles, and strand chevrons."""
    import matplotlib.patches as mpatches
    ax.plot([gene_start, gene_end], [y, y], color=color, lw=line_width, zorder=2, solid_capstyle="butt")
    for s, e in zip(exon_starts, exon_ends):
        rect = mpatches.Rectangle((s, y - exon_height / 2), max(e - s, 1), exon_height,
                                    facecolor=color, edgecolor="none", zorder=3)
        ax.add_patch(rect)
    draw_strand_arrows(ax, gene_start, gene_end, y, strand, color, n=max(2, int((gene_end - gene_start) / 8000)))


def merged_exons_for_gene(gene_id, tx_df, exon_df):
    """Union all exons across all transcripts of gene_id into non-overlapping
    blocks (for a whole-gene 'meta exon' row in a region-level diagram)."""
    tx_ids = tx_df[tx_df.gene_id == gene_id].transcript_id
    ex = exon_df[exon_df.transcript_id.isin(tx_ids)][["start", "end"]].sort_values("start").values.tolist()
    if not ex:
        return []
    merged = [ex[0]]
    for s, e in ex[1:]:
        if s <= merged[-1][1] + 1:
            merged[-1][1] = max(merged[-1][1], e)
        else:
            merged.append([s, e])
    return merged


def pair_frame_with_biotypes(result):
    pairs = result["overlap_pairs"].copy()
    eg, ng = result["ensembl"]["genes"], result["ncbi"]["genes"]
    pairs["ens_biotype"] = eg.loc[pairs.a_idx, "biotype_norm"].values
    pairs["ncbi_biotype"] = ng.loc[pairs.b_idx, "biotype_norm"].values
    pairs["ens_gene_id"] = eg.loc[pairs.a_idx, "gene_id"].values
    pairs["ncbi_gene_id"] = ng.loc[pairs.b_idx, "gene_id"].values
    es, ee = eg.loc[pairs.a_idx, "start"].values, eg.loc[pairs.a_idx, "end"].values
    ns, ne = ng.loc[pairs.b_idx, "start"].values, ng.loc[pairs.b_idx, "end"].values
    ov = (np.minimum(ee, ne) - np.maximum(es, ns) + 1).clip(min=0)
    short = np.minimum(ee - es + 1, ne - ns + 1)
    pairs["overlap_frac"] = ov / short
    return pairs


def pick_example_region_locus(result, biotype_a="lncRNA", biotype_b="protein_coding",
                               min_cluster=3, max_cluster=15, pad=5000):
    """Auto-select a real 'nested annotation' example: an NCBI gene of
    biotype_b that a moderate cluster (min_cluster..max_cluster) of Ensembl
    biotype_a genes disagree-overlap with — the same pattern as e.g. GNAS or
    LEPR (several intronic/nested Ensembl calls inside one NCBI gene body).
    Returns a dict with the region bounds and both providers' gene tables for
    that window, or None if no locus in range is found. No hardcoded gene
    names — works for any organism's `compare_annotations(...)` result."""
    pairs = pair_frame_with_biotypes(result)
    hc = pairs[pairs.overlap_frac > 0.5]
    disagree = hc[hc.ens_biotype != hc.ncbi_biotype]
    sub = disagree[(disagree.ens_biotype == biotype_a) & (disagree.ncbi_biotype == biotype_b)]
    if len(sub) == 0:
        return None
    counts = sub["ncbi_gene_id"].value_counts()
    counts = counts[(counts >= min_cluster) & (counts <= max_cluster)]
    if len(counts) == 0:
        return None
    target_ncbi_id = counts.sort_values().index[len(counts) // 2]  # a representative, not the extreme

    ncbi_genes, ens_genes = result["ncbi"]["genes"], result["ensembl"]["genes"]
    ncbi_row = ncbi_genes[ncbi_genes.gene_id == target_ncbi_id].iloc[0]
    chrom_ncbi = ncbi_row["seqid"]
    chrom_ens = result["chrom_map"].get(chrom_ncbi)
    rs, re_ = ncbi_row["start"] - pad, ncbi_row["end"] + pad

    ens_region = ens_genes[(ens_genes.seqid == chrom_ens) & (ens_genes.end >= rs) & (ens_genes.start <= re_)]
    ncbi_region = ncbi_genes[(ncbi_genes.seqid == chrom_ncbi) & (ncbi_genes.end >= rs) & (ncbi_genes.start <= re_)]
    return {
        "ncbi_gene_id": target_ncbi_id, "chrom_ens": chrom_ens, "chrom_ncbi": chrom_ncbi,
        "xmin": rs, "xmax": re_, "ens_region": ens_region, "ncbi_region": ncbi_region,
    }


def pick_example_isoform_locus(result, min_tx=2, max_tx=6, overlap_frac_min=0.8):
    """Auto-select a 1:1-matched protein-coding gene pair with a modest,
    DIFFERING transcript count on each side (min_tx..max_tx) — compact enough
    to draw cleanly, and different enough to be a meaningful isoform-model
    example. Returns a dict with the gene ids/rows, or None if none found."""
    pairs = pair_frame_with_biotypes(result)
    pc = pairs[(pairs.ens_biotype == "protein_coding") & (pairs.ncbi_biotype == "protein_coding")
               & (pairs.overlap_frac > overlap_frac_min)]
    pc = pc.sort_values("overlap_frac", ascending=False).drop_duplicates("a_idx").drop_duplicates("b_idx")

    ens_tx, ncbi_tx = result["ensembl"]["transcripts"], result["ncbi"]["transcripts"]
    tpg_ens = ens_tx.groupby("gene_id").size().to_dict()
    tpg_ncbi = ncbi_tx.groupby("gene_id").size().to_dict()
    pc = pc.assign(ens_ntx=pc.ens_gene_id.map(tpg_ens).fillna(0).astype(int),
                   ncbi_ntx=pc.ncbi_gene_id.map(tpg_ncbi).fillna(0).astype(int))
    cand = pc[pc.ens_ntx.between(min_tx, max_tx) & pc.ncbi_ntx.between(min_tx, max_tx)
              & (pc.ens_ntx != pc.ncbi_ntx)]
    if len(cand) == 0:
        return None
    row = cand.iloc[len(cand) // 2]  # a representative pick, not the first alphabetically

    ens_genes, ncbi_genes = result["ensembl"]["genes"], result["ncbi"]["genes"]
    ens_gene_row = ens_genes[ens_genes.gene_id == row.ens_gene_id].iloc[0]
    ncbi_gene_row = ncbi_genes[ncbi_genes.gene_id == row.ncbi_gene_id].iloc[0]
    return {
        "ens_gene_id": row.ens_gene_id, "ncbi_gene_id": row.ncbi_gene_id,
        "ens_gene_row": ens_gene_row, "ncbi_gene_row": ncbi_gene_row,
        "ens_ntx": int(row.ens_ntx), "ncbi_ntx": int(row.ncbi_ntx),
    }


def plot_region_comparison(ens_region, ncbi_region, ens_tx, ens_exons, ncbi_tx, ncbi_exons,
                            xmin, xmax, chrom_label, ens_release_label, ncbi_release_label,
                            suptitle, savepath):
    """Two-track 'genome browser' style figure: Ensembl genes on top, NCBI
    RefSeq genes below, sharing an x-axis, gene models drawn to scale and
    colored by biotype. `ens_region`/`ncbi_region` are gene-table slices
    (e.g. from `pick_example_region_locus(...)['ens_region']`)."""
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    import pandas as pd

    ens_rows = ens_region.sort_values("start").reset_index(drop=True)
    ncbi_rows = ncbi_region.sort_values("start").reset_index(drop=True)
    fig, axes = plt.subplots(
        2, 1, figsize=(11, 0.5 * max(len(ens_rows), 1) + 0.5 * max(len(ncbi_rows), 1) + 2.0),
        sharex=True, gridspec_kw={"height_ratios": [max(len(ens_rows), 1), max(len(ncbi_rows), 1)]})

    ax = axes[0]
    for i, row in ens_rows.iterrows():
        y = len(ens_rows) - i
        color = LOCUS_BIOTYPE_COLORS.get(row.biotype_norm, "#999999")
        exons = merged_exons_for_gene(row.gene_id, ens_tx, ens_exons) or [[row.start, row.end]]
        ex_s, ex_e = zip(*exons)
        draw_gene_model(ax, y, ex_s, ex_e, row.start, row.end, row.strand, color)
        label = row.gene_name if pd.notna(row.get("gene_name")) else row.gene_id
        ax.text(xmax + (xmax - xmin) * 0.012, y, f"{label}", va="center", ha="left",
                fontsize=7, color=color, fontweight="bold")
    ax.set_ylim(0.3, len(ens_rows) + 0.7)
    ax.set_yticks([])
    ax.set_title(f"Ensembl ({ens_release_label})", loc="left", fontsize=9)
    set_locus_axis_frame(ax, "open")
    ax.spines["left"].set_visible(False)

    ax2 = axes[1]
    for i, row in ncbi_rows.iterrows():
        y = len(ncbi_rows) - i
        color = LOCUS_BIOTYPE_COLORS.get(row.biotype_norm, "#999999")
        exons = merged_exons_for_gene(row.gene_id, ncbi_tx, ncbi_exons) or [[row.start, row.end]]
        ex_s, ex_e = zip(*exons)
        draw_gene_model(ax2, y, ex_s, ex_e, row.start, row.end, row.strand, color)
        ax2.text(xmax + (xmax - xmin) * 0.012, y, f"{row.gene_id}", va="center", ha="left",
                 fontsize=7, color=color, fontweight="bold")
    ax2.set_ylim(0.3, len(ncbi_rows) + 0.7)
    ax2.set_yticks([])
    ax2.set_title(f"NCBI RefSeq ({ncbi_release_label})", loc="left", fontsize=9)
    set_locus_axis_frame(ax2, "open")
    ax2.spines["left"].set_visible(False)
    ax2.set_xlabel(f"{chrom_label} position (bp)")
    ax2.set_xlim(xmin, xmax)
    ax2.xaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"{x/1e6:.3f} Mb"))

    present_bts = sorted(set(ens_rows.biotype_norm) | set(ncbi_rows.biotype_norm),
                          key=lambda b: list(LOCUS_BIOTYPE_COLORS).index(b) if b in LOCUS_BIOTYPE_COLORS else 99)
    handles = [mpatches.Patch(color=LOCUS_BIOTYPE_COLORS.get(b, "#999999"), label=LOCUS_BIOTYPE_DISPLAY.get(b, b))
               for b in present_bts]
    fig.legend(handles=handles, loc="lower center", ncol=len(handles), frameon=False,
               bbox_to_anchor=(0.42, -0.02), fontsize=7.5)
    fig.suptitle(suptitle, fontsize=9.5, x=0.02, ha="left", y=1.01)
    fig.subplots_adjust(right=0.82, bottom=0.16, hspace=0.35)
    fig.savefig(savepath, dpi=300, bbox_inches="tight")
    plt.close(fig)


def plot_isoform_comparison(ens_gene_id, ncbi_gene_id, ens_gene_row, ncbi_gene_row,
                             ens_tx, ens_exons, ncbi_tx, ncbi_exons,
                             ens_label, ncbi_label, chrom_label, suptitle, savepath):
    """Two-track figure showing every transcript model of one matched gene on
    each side (Ensembl top, NCBI RefSeq bottom) — for comparing isoform/exon
    structure at a single locus rather than gene calls across a region."""
    import matplotlib.pyplot as plt

    ens_col, ncbi_col = LOCUS_BIOTYPE_COLORS["protein_coding"], "#E07B39"
    ens_tx_sub = ens_tx[ens_tx.gene_id == ens_gene_id].sort_values("transcript_id").reset_index(drop=True)
    ncbi_tx_sub = ncbi_tx[ncbi_tx.gene_id == ncbi_gene_id].sort_values("transcript_id").reset_index(drop=True)
    xmin = min(ens_gene_row.start, ncbi_gene_row.start) - 300
    xmax = max(ens_gene_row.end, ncbi_gene_row.end) + 300

    fig, axes = plt.subplots(
        2, 1, figsize=(10, 0.55 * max(len(ens_tx_sub), 1) + 0.55 * max(len(ncbi_tx_sub), 1) + 1.6),
        sharex=True, gridspec_kw={"height_ratios": [max(len(ens_tx_sub), 1), max(len(ncbi_tx_sub), 1)]})

    ax = axes[0]
    for i, row in ens_tx_sub.iterrows():
        y = len(ens_tx_sub) - i
        ex = ens_exons[ens_exons.transcript_id == row.transcript_id][["start", "end"]].sort_values("start").values
        draw_gene_model(ax, y, ex[:, 0], ex[:, 1], row.start, row.end, ens_gene_row.strand, ens_col)
        ax.text(xmax + (xmax - xmin) * 0.012, y, row.transcript_id, va="center", ha="left", fontsize=7, color=ens_col)
    ax.set_ylim(0.3, len(ens_tx_sub) + 0.7)
    ax.set_yticks([])
    ax.set_title(f"{ens_label} — {ens_gene_id} ({len(ens_tx_sub)} transcript{'s' if len(ens_tx_sub) != 1 else ''})",
                 loc="left", fontsize=9, color=ens_col)
    set_locus_axis_frame(ax, "open")
    ax.spines["left"].set_visible(False)

    ax2 = axes[1]
    for i, row in ncbi_tx_sub.iterrows():
        y = len(ncbi_tx_sub) - i
        ex = ncbi_exons[ncbi_exons.transcript_id == row.transcript_id][["start", "end"]].sort_values("start").values
        draw_gene_model(ax2, y, ex[:, 0], ex[:, 1], row.start, row.end, ncbi_gene_row.strand, ncbi_col)
        ax2.text(xmax + (xmax - xmin) * 0.012, y, row.transcript_id, va="center", ha="left", fontsize=7, color=ncbi_col)
    ax2.set_ylim(0.3, len(ncbi_tx_sub) + 0.7)
    ax2.set_yticks([])
    ax2.set_title(f"{ncbi_label} — {ncbi_gene_id} ({len(ncbi_tx_sub)} transcript{'s' if len(ncbi_tx_sub) != 1 else ''})",
                  loc="left", fontsize=9, color=ncbi_col)
    set_locus_axis_frame(ax2, "open")
    ax2.spines["left"].set_visible(False)
    ax2.set_xlabel(f"{chrom_label} position (bp)")
    ax2.set_xlim(xmin, xmax)
    ax2.xaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f"{x/1e6:.3f} Mb"))
    fig.suptitle(suptitle, fontsize=9.5, x=0.02, ha="left", y=1.02)
    fig.subplots_adjust(right=0.8, bottom=0.16, hspace=0.4)
    fig.savefig(savepath, dpi=300, bbox_inches="tight")
    plt.close(fig)

