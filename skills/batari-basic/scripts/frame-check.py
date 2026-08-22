#!/usr/bin/env python3
"""frame-check.py SHOT.png [SHOT2.png ...]

Triage a batch of headless screenshots without opening every one of them.

It answers the two questions that come up constantly while iterating on a bB
game, both of which look identical from the outside (a .png got written):

  BLANK  - one colour covers nearly the whole frame. The program crashed, or
           never set a colour, or drew nothing. A black frame is the usual
           symptom of a wild `on x goto`, a runaway gosub, or a sprite whose
           graphics block never executed.
  FROZEN - this frame is pixel-identical to the previous one. The game locked
           up: an animation loop whose counter is clobbered by a subroutine
           using the same scratch variable, or a wait loop that can never
           reach its exit condition.

Anything reported OK is worth actually looking at - this tool tells you which
frames are worth the look, it does not tell you the game is correct. Colours,
sprite positions and layout can only be judged by eye.

    scripts/frame-check.py /tmp/shots/*.png
"""
import sys


def load(path):
    from PIL import Image
    return Image.open(path).convert("RGB")


def main(argv):
    paths = argv[1:]
    if not paths:
        print((__doc__ or "").strip(), file=sys.stderr)
        return 2

    try:
        import PIL.Image  # noqa: F401
    except ImportError:
        print("frame-check: needs Pillow  (pip install pillow)", file=sys.stderr)
        return 2

    prev_bytes = None
    prev_name = None
    problems = 0

    for path in paths:
        try:
            im = load(path)
        except Exception as exc:                      # unreadable / not a png
            print(f"{path}: ERROR {exc}")
            problems += 1
            continue

        total = im.size[0] * im.size[1]
        colors = sorted(im.getcolors(maxcolors=1 << 24) or [], reverse=True)
        top_n, top_rgb = colors[0]
        share = top_n / total

        raw = im.tobytes()
        flags = []

        if share > 0.99:
            flags.append(f"BLANK ({share:.1%} of frame is rgb{top_rgb})")
        if prev_bytes is not None and raw == prev_bytes:
            flags.append(f"FROZEN (identical to {prev_name})")

        if flags:
            problems += 1
            print(f"{path}: " + "; ".join(flags))
        else:
            distinct = len(colors)
            print(f"{path}: ok  ({distinct} colours, "
                  f"dominant rgb{top_rgb} {share:.0%})")

        prev_bytes = raw
        prev_name = path.split("/")[-1]

    print(f"\n{len(paths)} frame(s), {problems} flagged")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
