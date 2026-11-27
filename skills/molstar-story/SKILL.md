---
name: molstar-story
description: "Create interactive Mol* Stories web pages (.html and .mvsx) using molviewspec to walk readers through protein structures, interfaces, epitopes, and binder designs. Use when building multi-scene 3D structural walkthroughs, animated exploded views, epitope/hotspot showcases, or self-contained offline structural biology presentations."
compatibility: Requires Python 3.10+ and uv (or pip) for molviewspec; PyMOL (pymol-open-source-whl) or gemmi/BioPython recommended for pre-aligning structures.
---

# Mol* Stories (`molviewspec`)

## When to Use This Skill

Use this skill when creating an interactive, multi-scene 3D structural walkthrough in Mol* Stories format - for example:

- Explaining receptor or complex architecture across multiple aligned structures/models
- Highlighting targeted epitopes, hotspots, or disrupted endogenous interfaces
- Showcasing designed protein binders or ligands alongside displaced native partners (using light transparent grey or animated exploded views)
- Packaging a self-contained `.html` story (and `.mvsx` archive) with embedded local `.cif` files that works offline in any browser

## Recommended Two-Stage Workflow

Always separate **structure preparation** from **story assembly**:

1. **Stage 1 - Pre-align and split structures (`prepare_story_structures.py`)**
   - Superimpose all reference structures, domain models, and binder complexes into one canonical coordinate frame (e.g. principal axis horizontal along `+X`, functional axis along `+Y`, viewer looking down `-Z`).
   - Export **each independently styled, animated, or non-contiguous component as its own `.cif` file** into a subfolder (e.g. `story_structures/target.cif`, `partner.cif`, `binder_01.cif`). Never pack disjoint residue ranges (e.g. N-terminus + a distant rebuilt loop) into one chain with consecutive `label_seq_id` values, or Mol\* will draw a dashed chain-break line across the gap.
   - Splitting into single-component `.cif` files avoids complex per-chain transform math inside MolViewSpec and makes exploded-view animations trivial.
   - Print atom centroids `(x, y, z)` of every exported component (and `CA` coordinates of any key residues you plan to annotate) so you can set exact `camera(position, target, up)` and perimeter callout coordinates for each scene.

2. **Stage 2 - Build the Mol* Story (`build_molstar_story.py`)**
   - Read [references/story_template.py](references/story_template.py) when starting Stage 2 for a complete runnable builder with helpers (`load_cifs`, `atom_xyz`, `add_callouts`, `add_cartoon`, `add_sticks`, `add_hotspots`, `sw`).
   - Load the exported `.cif` bytes into a `dict[str, bytes]` (`data = {"target.cif": ...}`).
   - Build a list of `mvs.Snapshot` objects via `mvs.create_builder()`.
   - Combine into `mvs.States(metadata=mvs.GlobalMetadata(...), snapshots=[...])`.
   - Export both:
     - Self-contained HTML: `mvs.molstar_html(states, data=data, ui="stories")`
     - Portable archive: `mvs.MVSX(data=states, assets=data).dump("story.mvsx")`
   - Post-process the generated `.html` with `scripts/inject_controls.py` to add UTF-8 encoding, a persistent `Hide Labels` / `Show Labels` toolbar button, and clickable color-swatch visibility toggles:
     ```bash
     uv run --with molviewspec build_molstar_story.py
     python <skill-dir>/scripts/inject_controls.py design_story.html
     ```

## Visual & Narrative Conventions

A clear structural design story typically follows 4-8 snapshots:

1. **Architecture overview** - Full reference complex in canonical orientation (reference backbone in translucent grey `#cfd5df`, `opacity=0.22`; primary target domains in saturated colors).
2. **Exploded domain view (animated)** - Separate domains/partners using `transform_matrix` interpolation so readers see the modular interfaces.
3. **Epitopes & disrupted interfaces** - Render endogenous partners (native ligand, coactivator peptide, DNA, or partner chain) in **very light transparent grey** (`#d4d8e0`, `opacity=0.20-0.25`) and highlight hotspot residues as **spacefilling spheres** (`type="spacefill"`).
4. **Top binders per epitope** - Zoom onto the targeted domain with 2-3 top designs in distinct colors, keeping the displaced native partner in very light transparent grey to show steric overlap or orthogonality.
5. **Exploded displacement view (animated)** - Keep the target + top binder stationary while animating the displaced endogenous partner outward along the interface normal.
6. **Full-complex summary** - Return to the overview frame with representative binders at each targeted site.

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
- **Color functionally distinct sidechain groups separately:** In interface close-ups, give each key interaction role its own distinct color (e.g. hydrophobic anchor vs salt-bridge partner vs peripheral rim vs structural disulfide) rather than coloring all interface sticks identically.
- **Use interactive inline color-swatch squares in sidebar text instead of only naming colors:** Mol\* Stories (`mvs-stories.js`) renders Markdown through `react-markdown` with `skipHtml: true`, so raw HTML like `<span style="color:...">` is silently stripped. Instead, use the native `color-swatch` image extension so the sidebar reads like a true visual legend matching the exact 3D hex colors in both `.html` and `.mvsx`. Attach a unique `ref` to every representation (`rep_ref=...`) and bind it in `sw()` so hovering highlights the 3D feature natively and clicking toggles its visibility on/off in the standalone HTML (with a high-contrast diagonal slash across toggled-off squares):
  ```python
  def sw(hex_color: str, refs: str | None = None) -> str:
      img = f"![](!color-swatch={hex_color})"
      if refs:
          return f"[{img}](!toggle-refs={refs}&highlight-refs={refs})"
      return img
  ```
  - Example: `f"- {sw('#d946ef', 's1_hotspots')} **PD-L1 hotspots (`Tyr56`, `Met115`, `Tyr123`)** on {sw('#2563eb', 's1_target')} **PD-L1**"`
  - Multiple representations can share one swatch by comma-separating refs: `sw('#0ea5e9', 's2_binder,s2_binder_sticks')`.
  - Never wrap `sw(...)` inside inline code backticks (that renders the syntax literally).
  - Because the Mol\* Stories sidebar background is light warm grey (`#F6F5F3`), use a slightly darker swatch hex (e.g. `#b8c0cc`) when representing very light transparent grey (`#d4d8e0`) partners so the square remains clearly legible.
- **Avoid LaTeX `$...$` math in descriptions:** `mvs-stories.js` does not include MathJax/KaTeX, so `$K_d = 10$` or `$\Delta G$` render with literal dollar signs. Use plain Unicode (`Kd = 10 nM`, `ΔG`, `χ1`, `β-sheet`, `⇌`, `Å`) instead.
- **Optional text hover/focus links:** Attach `ref="s1_hotspots"` to a component and link to it in Markdown with `[Tyr56](!highlight-refs=s1_hotspots&focus-refs=s1_hotspots)` so hovering highlights and clicking focuses the 3D residue.

### Offset Callout Labels, Leader Lines & Interactive Standalone Controls

Instead of placing 3D labels directly on top of atoms (where they obscure sidechains and ribbons), place labels on a clean perimeter ring around the protein connected by dashed leader lines, and pair them with the interactive controls injected by [scripts/inject_controls.py](scripts/inject_controls.py):

1. **Offset callout labels + dashed leader lines (`ref="scene_labels"`):**
   - Put all callouts for a snapshot inside a single `b.primitives(ref="scene_labels", ...)` node so one toggle hides/shows every label, leader line, and anchor dot together.
   - Pass **absolute perimeter coordinates `(lx, ly, lz)`** for each label rather than fixed relative `(dx, dy, dz)` offsets. Relative offsets push residues already near the top or side of the fold off-canvas or underneath the top `[x/N]` selector and right Mol\* toolbar.
   - Keep callout strings concise (<=24 chars), use `label_size=1.45-1.55`, and pull the camera back ~8-10 Å relative to an unlabelled close-up so the margin ring stays clear.
   ```python
   def add_callouts(
       b: mvs.builder.Root,
       items: list[tuple[str, int, str, tuple[float, float, float], str]],
       label_size: float = 1.50,
   ) -> None:
       """Each item: (cif_filename, label_seq_id, text, (lx, ly, lz), line_color)."""
       prims = b.primitives(ref="scene_labels", label_opacity=1.0, opacity=0.92)
       for filename, seq_id, text, p1, color in items:
           p0 = atom_xyz(filename, seq_id)  # CA coordinates from the aligned .cif
           prims.sphere(center=p0, radius=0.28, color=color)
           prims.tube(start=p0, end=p1, radius=0.07, dash_length=0.45, color=color)
           prims.label(position=p1, text=text, label_size=label_size, label_color="#111827")
   ```

2. **Persistent `Hide Labels` button & clickable color-swatch toggles (`scripts/inject_controls.py`):**
   - Run `python <skill-dir>/scripts/inject_controls.py design_story.html` (updates in place; pass `-o out.html` or `-o -` to write elsewhere) after generating HTML with `mvs.molstar_html(states, data=data, ui="stories")`.
   - The script injects:
     - **`<meta charset="utf-8">`** in `<head>` (prevents `file://` browsers from falling back to `windows-1252` on Unicode symbols).
     - A **`#story-toolbar`** bar at the top of `#controls` with a **`Hide Labels` / `Show Labels`** button (`#toggle-labels-btn`) that toggles the `scene_labels` subtree and **persists across scene changes** via `plugin.managers.snapshot.events.changed`.
     - A **`toggle-refs`** Markdown extension that resolves MVS `ref` tags via `plugin.managers.markdownExtensions.findCells(refs)` and toggles visibility across the full cell subtree.
     - A **`.swatch-hidden`** CSS state that dims toggled-off color squares (`opacity: 0.35`) with a high-contrast diagonal slash.
   - If the target project needs `build_molstar_story.py` to remain self-contained without calling the skill script, import `inject_interactive_controls` from `scripts/inject_controls.py` or copy it into the project script.
   - Always verify the built `.html` in a browser (check zero console errors, confirm `document.characterSet === "UTF-8"`, click `Hide Labels` and advance scenes to verify persistence, click a color swatch to confirm both 3D hiding and the diagonal slash, and visually check that no callout label clips against the canvas edge or toolbars).

## Key Gotchas (`molviewspec >= 1.8`)

Check installed API signatures on demand when unsure:
```bash
uv run --with molviewspec python -c "import inspect, molviewspec as mvs; print(inspect.signature(mvs.molstar_html))"
```

Keep these recurring traps in mind:

- **PyMOL-exported mmCIF `label_asym_id` trap:** PyMOL writes `_atom_site.label_asym_id` as `.` while populating `label_seq_id` and `auth_asym_id`. Standard RCSB-style `ComponentExpression(label_asym_id="A", label_seq_id=56)` will silently select **zero atoms** on PyMOL-saved `.cif` files. Either omit `label_asym_id` (safe when each `.cif` is a single chain) or match `auth_asym_id` + `label_seq_id`.
- **`molstar_html` omits `<meta charset="utf-8">`:** Browsers opening a local `file://` HTML story without a charset tag default to `windows-1252`, mangling `Å`, `χ`, `β`, `⇌`, and `•`. Always run `scripts/inject_controls.py` (or inject `<meta charset="utf-8">` into `<head>`) before opening the HTML file.
- **Resolving MVS `ref` nodes in custom JS:** MolViewSpec does not use your custom `ref` string directly as the Mol\* state tree key - it stores it as tag `mvs-ref:<name>` on an auto-generated `!mvs:...` cell key. Always resolve refs with `plugin.managers.markdownExtensions.findCells(refs)` rather than `plugin.state.data.cells.get(ref)`, and toggle the entire subtree via `plugin.state.data.tree.children` (essential for `primitives` nodes, whose `Mesh` and `Labels` visuals live on child cells).
- **Disjoint segments in one chain draw dashed chain breaks:** If you pack two non-contiguous residue stretches (e.g. residues `10-20` and `90-100`) into one `.cif` chain with consecutive `label_seq_id`, Mol\* draws a dashed gap line between them. Export each contiguous stretch to its own `.cif` file instead.
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
- **Keep bundles lightweight:** Strip waters/solvents and export only the chains needed for the story; a 10-20 structure story typically packs into ~300-600 KB as standalone HTML.

## Bundled Files & External References

- [references/story_template.py](references/story_template.py) - Full runnable Stage 2 PD-L1 template (`load_cifs`, `atom_xyz`, `add_callouts`, `add_cartoon`, `add_sticks`, `add_hotspots`, `sw`, animated exploded view). Read this when scaffolding `build_molstar_story.py`.
- [scripts/inject_controls.py](scripts/inject_controls.py) - Standalone CLI post-processor (and importable `inject_interactive_controls`) that adds `<meta charset="utf-8">`, the persistent `Hide Labels` toolbar, and clickable swatch toggles to `mvs.molstar_html(..., ui="stories")` output.
- [MolViewSpec documentation](https://molstar.org/mol-view-spec/)
- [Mol* Stories builder](https://molstar.org/stories-builder/)
