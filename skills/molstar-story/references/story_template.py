#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10, <3.13"
# dependencies = ["molviewspec>=1.8.0"]
# ///
"""Minimal Stage 2 Mol* Story builder template.

Example: PD-L1 (4ZQK chain A) with its displaced native partner PD-1 (4ZQK chain B)
and a designed binder (binder_01.cif), pre-aligned in story_structures/.

Run:
    uv run --with molviewspec build_molstar_story.py
    python <skill-dir>/scripts/inject_controls.py design_story.html
"""

from pathlib import Path
import molviewspec as mvs

STRUCT_DIR = Path("story_structures")
_COORD_CACHE: dict[str, dict[tuple[int, str], tuple[float, float, float]]] = {}


def load_cifs(directory: Path) -> dict[str, bytes]:
    return {f.name: f.read_bytes() for f in sorted(directory.glob("*.cif"))}


def atom_xyz(
    filename: str,
    label_seq_id: int,
    preferred_atoms: tuple[str, ...] = ("CA",),
) -> tuple[float, float, float]:
    """Read (x, y, z) for a residue atom from a pre-aligned story mmCIF."""
    if filename not in _COORD_CACHE:
        coords: dict[tuple[int, str], tuple[float, float, float]] = {}
        cols: list[str] = []
        in_loop = False
        i_atom = i_x = i_y = i_z = i_seq = -1
        for line in (STRUCT_DIR / filename).read_text(encoding="utf-8").splitlines():
            s = line.strip()
            if s == "loop_":
                cols, in_loop = [], False
            elif s.startswith("_atom_site."):
                cols.append(s)
                in_loop = True
                i_atom = cols.index("_atom_site.label_atom_id") if "_atom_site.label_atom_id" in cols else -1
                i_x = cols.index("_atom_site.Cartn_x") if "_atom_site.Cartn_x" in cols else -1
                i_y = cols.index("_atom_site.Cartn_y") if "_atom_site.Cartn_y" in cols else -1
                i_z = cols.index("_atom_site.Cartn_z") if "_atom_site.Cartn_z" in cols else -1
                i_seq = cols.index("_atom_site.label_seq_id") if "_atom_site.label_seq_id" in cols else -1
            elif in_loop and s.startswith("ATOM "):
                parts = s.split()
                try:
                    coords[(int(parts[i_seq]), parts[i_atom])] = (
                        float(parts[i_x]),
                        float(parts[i_y]),
                        float(parts[i_z]),
                    )
                except (ValueError, IndexError):
                    pass
            elif in_loop and s and not s.startswith(("ATOM ", "HETATM")):
                in_loop = False
        _COORD_CACHE[filename] = coords

    table = _COORD_CACHE[filename]
    for atom_name in (*preferred_atoms, "CA"):
        if (label_seq_id, atom_name) in table:
            return table[(label_seq_id, atom_name)]
    raise KeyError(f"Atom {preferred_atoms} not found for residue {label_seq_id} in {filename}")


def add_callouts(
    b: mvs.builder.Root,
    items: list[tuple[str, int, str, tuple[float, float, float], str]],
    label_size: float = 1.50,
) -> None:
    """Add perimeter callout labels + dashed leader lines under ref='scene_labels'.

    Each item is (cif_filename, label_seq_id, text, (lx, ly, lz), line_color).
    """
    prims = b.primitives(ref="scene_labels", label_opacity=1.0, opacity=0.92)
    for filename, seq_id, text, p1, color in items:
        p0 = atom_xyz(filename, seq_id)
        prims.sphere(center=p0, radius=0.28, color=color)
        prims.tube(start=p0, end=p1, radius=0.07, dash_length=0.45, color=color)
        prims.label(position=p1, text=text, label_size=label_size, label_color="#111827")


def add_cartoon(
    b: mvs.builder.Root,
    filename: str,
    color: str,
    opacity: float = 1.0,
    transform_ref: str | None = None,
    rep_ref: str | None = None,
):
    s = b.download(url=filename).parse(format="mmcif").model_structure()
    if transform_ref is not None:
        s = s.transform(translation=(0.0, 0.0, 0.0), ref=transform_ref)
    rep = s.component(selector="all").representation(type="cartoon", ref=rep_ref).color(color=color)
    if opacity < 1.0:
        rep.opacity(opacity=opacity)
    return s


def sw(hex_color: str, refs: str | None = None) -> str:
    img = f"![](!color-swatch={hex_color})"
    if refs:
        return f"[{img}](!toggle-refs={refs}&highlight-refs={refs})"
    return img


def add_sticks(
    struct,
    res_ids: list[int],
    color: str,
    size_factor: float = 0.65,
    rep_ref: str | None = None,
):
    exprs = [mvs.ComponentExpression(label_seq_id=r) for r in res_ids]
    return (
        struct.component(selector=exprs)
        .representation(
            type="ball_and_stick",
            size_factor=size_factor,
            custom={"molstar_representation_params": {"sizeAspectRatio": 1}},
            ref=rep_ref,
        )
        .color(color=color)
    )


def add_hotspots(struct, res_ids: list[int], color: str, rep_ref: str | None = None):
    exprs = [mvs.ComponentExpression(label_seq_id=r) for r in res_ids]
    return (
        struct.component(selector=exprs)
        .representation(type="spacefill", ref=rep_ref)
        .color(color=color)
    )


def snap_overview() -> mvs.Snapshot:
    b = mvs.create_builder()
    target = add_cartoon(b, "pdl1_target.cif", "#2563eb", rep_ref="s1_target")
    add_hotspots(target, [56, 115, 123], "#d946ef", rep_ref="s1_hotspots")
    add_cartoon(b, "pd1_partner.cif", "#d4d8e0", opacity=0.25, rep_ref="s1_partner")
    add_callouts(
        b,
        [
            ("pdl1_target.cif", 56, "Tyr56 hotspot", (-18.0, 14.0, 10.0), "#d946ef"),
            ("pdl1_target.cif", 115, "Met115 hotspot", (18.0, 12.0, 10.0), "#d946ef"),
            ("pdl1_target.cif", 123, "Tyr123 hotspot", (18.0, -14.0, 10.0), "#d946ef"),
        ],
    )
    b.camera(position=(0.0, 0.0, 85.0), target=(0.0, 0.0, 0.0), up=(0.0, 1.0, 0.0))
    return b.get_snapshot(
        title="1. Target & Native Interface",
        description=(
            f"### PD-L1 Epitope\n\n"
            f"{sw('#d946ef', 's1_hotspots')} **Hotspot residues (magenta spheres)** on "
            f"{sw('#2563eb', 's1_target')} **PD-L1** overlap the native "
            f"{sw('#b8c0cc', 's1_partner')} **PD-1** interface (light transparent grey)."
        ),
        description_format="markdown",
        linger_duration_ms=7000,
        transition_duration_ms=1000,
    )


def snap_exploded_binder() -> mvs.Snapshot:
    b = mvs.create_builder()
    target = add_cartoon(b, "pdl1_target.cif", "#2563eb", rep_ref="s2_target")
    add_hotspots(target, [56, 115, 123], "#d946ef", rep_ref="s2_hotspots")
    add_cartoon(b, "binder_01.cif", "#0ea5e9", rep_ref="s2_binder")
    add_cartoon(
        b, "pd1_partner.cif", "#cbd5e1", opacity=0.35,
        transform_ref="displaced_partner", rep_ref="s2_partner",
    )

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
        description=(
            f"### Competitive Displacement\n\n"
            f"Designed {sw('#0ea5e9', 's2_binder')} **binder** occupies the "
            f"{sw('#d946ef', 's2_hotspots')} epitope on {sw('#2563eb', 's2_target')} **PD-L1** "
            f"while native {sw('#b8c0cc', 's2_partner')} **PD-1** animates outward."
        ),
        description_format="markdown",
        linger_duration_ms=7000,
        transition_duration_ms=1000,
    )


def main() -> None:
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
