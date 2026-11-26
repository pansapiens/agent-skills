---
name: molstar-story
description: "Create interactive Mol* Stories web pages (.html and .mvsx) using molviewspec to walk readers through protein structures, interfaces, epitopes, and binder designs."
compatibility: Requires Python 3.10+ and uv (or pip) for molviewspec; PyMOL (pymol-open-source-whl) or gemmi/BioPython recommended for pre-aligning structures.
---

# Mol* Stories (`molviewspec`)

## When to Use This Skill

Use this skill when creating an interactive, multi-scene 3D structural walkthrough in Mol* Stories format — for example:

- Explaining receptor or complex architecture across multiple aligned structures/models
- Highlighting targeted epitopes, hotspots, or disrupted endogenous interfaces
- Showcasing designed protein binders or ligands alongside displaced native partners (using light transparent grey or animated exploded views)
- Packaging a self-contained `.html` story (and `.mvsx` archive) with embedded local `.cif` files that works offline in any browser

## Recommended Two-Stage Workflow

Always separate **structure preparation** from **story assembly**:

1. **Stage 1 — Pre-align and split structures (`prepare_story_structures.py`)**
   - Superimpose all reference structures, domain models, and binder complexes into one canonical coordinate frame (e.g. principal axis horizontal along `+X`, functional axis along `+Y`, viewer looking down `-Z`).
   - Export **each independently styled or animated component as its own `.cif` file** into a subfolder (e.g. `story_structures/target.cif`, `partner.cif`, `binder_01.cif`).
   - Splitting into single-component `.cif` files avoids complex per-chain transform math inside MolViewSpec and makes exploded-view animations trivial.
   - Print atom centroids `(x, y, z)` of every exported component so you can set exact `camera(position, target, up)` coordinates for each scene.

2. **Stage 2 — Build the Mol* Story (`build_molstar_story.py`)**
   - Load the exported `.cif` bytes into a `dict[str, bytes]` (`data = {"target.cif": ...}`).
   - Build a list of `mvs.Snapshot` objects via `mvs.create_builder()`.
   - Combine into `mvs.States(metadata=mvs.GlobalMetadata(...), snapshots=[...])`.
   - Export both:
     - Self-contained HTML: `mvs.molstar_html(states, data=data, ui="stories")`
     - Portable archive: `mvs.MVSX(data=states, assets=data).dump("story.mvsx")`

## Visual & Narrative Conventions

A clear structural design story typically follows 4–8 snapshots:

1. **Architecture overview** — Full reference complex in canonical orientation (reference backbone in translucent grey `#cfd5df`, `opacity=0.22`; primary target domains in saturated colors).
2. **Exploded domain view (animated)** — Separate domains/partners using `transform_matrix` interpolation so readers see the modular interfaces.
3. **Epitopes & disrupted interfaces** — Render endogenous partners (native ligand, coactivator peptide, DNA, or partner chain) in **very light transparent grey** (`#d4d8e0`, `opacity=0.20–0.25`) and highlight hotspot residues as **spacefilling spheres** (`type="spacefill"`).
4. **Top binders per epitope** — Zoom onto the targeted domain with 2–3 top designs in distinct colors, keeping the displaced native partner in very light transparent grey to show steric overlap or orthogonality.
5. **Exploded displacement view (animated)** — Keep the target + top binder stationary while animating the displaced endogenous partner outward along the interface normal.
6. **Full-complex summary** — Return to the overview frame with representative binders at each targeted site.

### Styling & Sidebar Legend Conventions

- **Prefer sticks over ball-and-stick for sidechains:** MolViewSpec's `ball_and_stick` representation defaults to chunky atom spheres. Render sidechains as clean uniform sticks (licorice) by setting `sizeAspectRatio: 1` via `molstar_representation_params`:
  ```python
  rep = (
      struct.component(selector=exprs)
      .representation(
          type="ball_and_stick",
          size_factor=0.65,
          custom={"molstar_representation_params": {"sizeAspectRatio": 1}},
      )
      .color(color=color)
  )
  ```
- **Color functionally distinct sidechain groups separately:** In interface close-ups, give each key interaction role its own distinct color (e.g. P1 anchor vs S1 pocket vs hydrophobic rim vs disulfide) rather than coloring all interface sticks identically.
- **Use inline color-swatch squares in sidebar text instead of only naming colors:** Mol\* Stories (`mvs-stories.js`) renders Markdown through `react-markdown` with `skipHtml: true`, so raw HTML like `<span style="color:...">` is silently stripped. Instead, use the native `color-swatch` image extension so the sidebar reads like a true visual legend matching the exact 3D hex colors in both `.html` and `.mvsx`:
  ```python
  def sw(hex_color: str) -> str:
      return f"![](!color-swatch={hex_color})"
  ```
  - Example: `f"- {sw('#2563eb')} **P1 Arg16 (royal blue sticks)** -> {sw('#ef4444')} **Asp208 (crimson sticks)**"`
  - Never wrap `sw(...)` inside inline code backticks (that renders the syntax literally).
  - Because the Mol\* Stories sidebar background is light warm grey (`#F6F5F3`), use a slightly darker swatch hex (e.g. `#b8c0cc`) when representing very light transparent grey (`#d4d8e0`) partners so the square remains clearly legible.
- **Avoid LaTeX `$...$` math in descriptions:** `mvs-stories.js` does not include MathJax/KaTeX, so `$E^*$` or `$K_i = 22$` render with literal dollar signs. Use plain Unicode (`E*`, `Ki = 22 nM`, `χ1`, `β-strand`, `⇌`, `Å`) instead.
- **Optional interactive hover/focus links:** Attach `ref="my_site"` to a component and link to it in Markdown with `[His67](!highlight-refs=my_site&focus-refs=my_site)` so hovering highlights and clicking focuses the 3D residue.

## Key Gotchas (`molviewspec >= 1.8`)

Check installed API signatures on demand when unsure:
```bash
uv run --with molviewspec python -c "import inspect, molviewspec as mvs; print(inspect.signature(mvs.molstar_html))"
```

Keep these recurring traps in mind:

- **PyMOL-exported mmCIF `label_asym_id` trap:** PyMOL writes `_atom_site.label_asym_id` as `.` while populating `label_seq_id` and `auth_asym_id`. Standard RCSB-style `ComponentExpression(label_asym_id="A", label_seq_id=56)` will silently select **zero atoms** on PyMOL-saved `.cif` files. Either omit `label_asym_id` (safe when each `.cif` is a single chain) or match `auth_asym_id` + `label_seq_id`.
- **`molstar_html` signature:** `mvs.molstar_html(states, data=data, ui="stories")` does **not** accept a `title=` keyword argument; set the title in `mvs.GlobalMetadata(title=..., description=...)`.
- **`MVSX` constructor:** Use `mvs.MVSX(data=states, assets=data)` (the `States` object is `data`, and the `dict[str, bytes]` file map is `assets`).
- **Type annotation:** The builder root class is `mvs.builder.Root`, not `mvs.Root`.
- **Exploded-view animations require a `transform` node with `ref`:** Attach `.transform(translation=(0.0, 0.0, 0.0), ref="my_part")` on the structure node, then target it with:
  ```python
  b.animation().interpolate(
      kind="transform_matrix",
      target_ref="my_part",
      property="matrix",
      start_ms=300,
      duration_ms=2000,
      translation_start=(0.0, 0.0, 0.0),
      translation_end=(16.0, 10.0, 0.0),
      translation_easing="cubic-out",
  )
  ```
- **Explicit cameras prevent jarring jumps:** Always call `b.camera(position=(...), target=(...), up=(0.0, 1.0, 0.0))` per snapshot using the precomputed component centroids rather than relying on auto-zoom.
- **Keep bundles lightweight:** Strip waters/solvents and export only the chains needed for the story; a 10–20 structure story typically packs into ~300–600 KB as standalone HTML.

## Minimal Working Template

Example: PD-L1 (`4ZQK` chain A) with its displaced native partner PD-1 (`4ZQK` chain B) and a designed binder (`binder_01.cif`), pre-aligned in `story_structures/`.

```python
# /// script
# requires-python = ">=3.10, <3.13"
# dependencies = ["molviewspec>=1.8.0"]
# ///
import os
import molviewspec as mvs

STRUCT_DIR = "story_structures"


def load_cifs(directory: str) -> dict[str, bytes]:
    return {
        f: open(os.path.join(directory, f), "rb").read()
        for f in sorted(os.listdir(directory))
        if f.endswith(".cif")
    }


def add_cartoon(
    b: mvs.builder.Root,
    filename: str,
    color: str,
    opacity: float = 1.0,
    ref: str | None = None,
):
    s = b.download(url=filename).parse(format="mmcif").model_structure()
    if ref is not None:
        s = s.transform(translation=(0.0, 0.0, 0.0), ref=ref)
    rep = s.component(selector="all").representation(type="cartoon").color(color=color)
    if opacity < 1.0:
        rep.opacity(opacity=opacity)
    return s


def sw(hex_color: str) -> str:
    return f"![](!color-swatch={hex_color})"


def add_sticks(struct, res_ids: list[int], color: str, size_factor: float = 0.65):
    exprs = [mvs.ComponentExpression(label_seq_id=r) for r in res_ids]
    return (
        struct.component(selector=exprs)
        .representation(
            type="ball_and_stick",
            size_factor=size_factor,
            custom={"molstar_representation_params": {"sizeAspectRatio": 1}},
        )
        .color(color=color)
    )


def add_hotspots(struct, res_ids: list[int], color: str):
    for r in res_ids:
        (
            struct.component(selector=mvs.ComponentExpression(label_seq_id=r))
            .representation(type="spacefill")
            .color(color=color)
        )


def snap_overview() -> mvs.Snapshot:
    b = mvs.create_builder()
    target = add_cartoon(b, "pdl1_target.cif", "#2563eb")
    add_hotspots(target, [56, 115, 123], "#d946ef")
    add_cartoon(b, "pd1_partner.cif", "#d4d8e0", opacity=0.25)
    b.camera(position=(0.0, 0.0, 85.0), target=(0.0, 0.0, 0.0), up=(0.0, 1.0, 0.0))
    return b.get_snapshot(
        title="1. Target & Native Interface",
        description=(
            f"### PD-L1 Epitope\n\n"
            f"{sw('#d946ef')} **Hotspot residues (magenta spheres)** on {sw('#2563eb')} **PD-L1** "
            f"overlap the native {sw('#b8c0cc')} **PD-1** interface (light transparent grey)."
        ),
        description_format="markdown",
        linger_duration_ms=7000,
        transition_duration_ms=1000,
    )


def snap_exploded_binder() -> mvs.Snapshot:
    b = mvs.create_builder()
    target = add_cartoon(b, "pdl1_target.cif", "#2563eb")
    add_hotspots(target, [56, 115, 123], "#d946ef")
    add_cartoon(b, "binder_01.cif", "#0ea5e9")
    add_cartoon(b, "pd1_partner.cif", "#cbd5e1", opacity=0.35, ref="displaced_partner")

    b.animation().interpolate(
        kind="transform_matrix",
        target_ref="displaced_partner",
        property="matrix",
        start_ms=300,
        duration_ms=2000,
        translation_start=(0.0, 0.0, 0.0),
        translation_end=(18.0, 10.0, 0.0),
        translation_easing="cubic-out",
    )
    b.camera(position=(0.0, 0.0, 95.0), target=(4.0, 2.0, 0.0), up=(0.0, 1.0, 0.0))
    return b.get_snapshot(
        title="2. Binder Displacement (Exploded View)",
        description="### Competitive Displacement\n\nDesigned binder (teal) occupies the epitope while native **PD-1** (grey) animates outward.",
        description_format="markdown",
        linger_duration_ms=7000,
        transition_duration_ms=1000,
    )


def main():
    data = load_cifs(STRUCT_DIR)
    states = mvs.States(
        metadata=mvs.GlobalMetadata(
            title="PD-L1 Binder Design Story",
            description="Interactive Mol* Stories walkthrough of target interface and designed binder.",
        ),
        snapshots=[snap_overview(), snap_exploded_binder()],
    )
    html = mvs.molstar_html(states, data=data, ui="stories")
    with open("design_story.html", "w", encoding="utf-8") as f:
        f.write(html)
    mvs.MVSX(data=states, assets=data).dump("design_story.mvsx")


if __name__ == "__main__":
    main()
```

Run with:
```bash
uv run --with molviewspec build_molstar_story.py
```

## References

- [MolViewSpec documentation](https://molstar.org/mol-view-spec/)
- [Mol* Stories builder](https://molstar.org/stories-builder/)
