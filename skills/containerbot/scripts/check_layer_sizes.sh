#!/bin/bash
# Report the layer sizes of a Docker/OCI image and flag any that are too large.
#
# Large layers are a practical problem: a blob transfer is not resumable *within*
# a blob, so one dropped connection re-downloads the entire layer. A single 8 GB
# layer turns a transient network blip into an 8 GB retry. Registries also impose
# their own ceilings (AWS ECR documents 10 GiB), and layers pull in parallel, so
# one huge layer serialises the pull.
#
# Requires: docker, python3

set -euo pipefail

MAX_GB=5
REMOTE=false

usage() {
    echo "Usage: $0 [--max-gb <N>] [--remote] <image>"
    echo ""
    echo "Report per-layer sizes for an image and flag layers over a threshold."
    echo ""
    echo "Options:"
    echo "  --max-gb <N>  Flag layers larger than N GB (default: 5)"
    echo "  --remote      Query the registry instead of the local image, even if"
    echo "                the image is present locally"
    echo ""
    echo "Modes:"
    echo "  local   (default when the image exists locally) uses 'docker history',"
    echo "          which shows UNCOMPRESSED sizes and the build step for each layer."
    echo "  remote  uses 'docker manifest inspect', which shows COMPRESSED blob"
    echo "          sizes - what the registry actually stores and transfers, and"
    echo "          therefore the number that matters for pull reliability."
    echo ""
    echo "Exits 1 if any layer exceeds the threshold, so it can gate CI."
    echo ""
    echo "Examples:"
    echo "  $0 myimage:latest"
    echo "  $0 --max-gb 2 myimage:latest"
    echo "  $0 --remote ghcr.io/owner/image:tag"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --max-gb)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --max-gb requires a value" >&2
                exit 1
            fi
            MAX_GB="$2"
            shift 2
            ;;
        --remote)
            REMOTE=true
            shift
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            IMAGE="$1"
            shift
            ;;
    esac
done

if [[ -z "${IMAGE:-}" ]]; then
    echo "Error: No image specified" >&2
    echo "Usage: $0 [--max-gb <N>] [--remote] <image>" >&2
    exit 1
fi

for cmd in docker python3; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo "Error: ${cmd} is not installed or not in PATH" >&2
        exit 1
    fi
done

if [[ "${REMOTE}" == "false" ]] && ! docker image inspect "${IMAGE}" &>/dev/null; then
    REMOTE=true
fi

if [[ "${REMOTE}" == "false" ]]; then
    # Local: docker history gives both size and the instruction that created it,
    # which is what you need to work out *why* a layer is large.
    docker history --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' "${IMAGE}" \
      | python3 -c "
import sys, re

max_bytes = float('${MAX_GB}') * 1e9
units = {'B': 1, 'kB': 1e3, 'KB': 1e3, 'MB': 1e6, 'GB': 1e9, 'TB': 1e12}

rows, over = [], 0
for line in sys.stdin:
    if '\t' not in line:
        continue
    size_s, step = line.rstrip('\n').split('\t', 1)
    m = re.match(r'^([0-9.]+)\s*([A-Za-z]+)$', size_s.strip())
    size = float(m.group(1)) * units.get(m.group(2), 1) if m else 0.0
    step = ' '.join(step.split())
    step = re.sub(r'^/bin/(sh|bash) -c ', '', step)
    step = re.sub(r'^#\(nop\)\s*', '', step)
    rows.append((size, step))

rows.reverse()  # oldest layer first, matching Dockerfile order
print('%3s %11s  %s' % ('#', 'size', 'step'))
for i, (size, step) in enumerate(rows):
    flag = '  <-- OVER ${MAX_GB} GB' if size > max_bytes else ''
    if size > max_bytes:
        over += 1
    print('%3d %8.2f GB  %s%s' % (i, size / 1e9, step[:90], flag))

total = sum(s for s, _ in rows)
print()
print('uncompressed total %.2f GB across %d layers; largest %.2f GB'
      % (total / 1e9, len(rows), max((s for s, _ in rows), default=0) / 1e9))
print('NOTE: these are UNCOMPRESSED sizes. Re-run with --remote after pushing to')
print('      see the compressed blob sizes the registry actually transfers.')
if over:
    print()
    print('FAIL: %d layer(s) over ${MAX_GB} GB' % over)
    sys.exit(1)
"
else
    # Remote: manifest layer sizes are the compressed blobs, i.e. what is actually
    # pushed and pulled. No build steps available without fetching the config blob.
    docker manifest inspect "${IMAGE}" 2>/dev/null | python3 -c "
import sys, json, subprocess

max_bytes = float('${MAX_GB}') * 1e9
image = '${IMAGE}'

try:
    data = json.load(sys.stdin)
except ValueError:
    sys.exit('Error: could not read manifest for %s (does it exist? are you logged in?)' % image)

# A multi-arch index has no layers of its own - resolve to a platform manifest.
if 'manifests' in data and 'layers' not in data:
    digest = None
    for m in data['manifests']:
        plat = m.get('platform', {})
        if plat.get('architecture') == 'amd64' and plat.get('os') == 'linux':
            digest = m['digest']
            break
    if digest is None:
        sys.exit('Error: no linux/amd64 manifest in the image index for %s' % image)
    # Strip any tag to get a bare repo ref we can re-address by digest. Only the
    # colon *after* the last slash is a tag separator - a registry host may carry
    # a port (localhost:5000/img), which must not be mistaken for one.
    ref = image.split('@')[0]
    slash = ref.rfind('/')
    colon = ref.rfind(':')
    if colon > slash:
        ref = ref[:colon]
    out = subprocess.run(['docker', 'manifest', 'inspect', '%s@%s' % (ref, digest)],
                         capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit('Error: could not inspect platform manifest %s' % digest)
    data = json.loads(out.stdout)

layers = data.get('layers', [])
if not layers:
    sys.exit('Error: no layers found in manifest for %s' % image)

print('%3s %11s  %s' % ('#', 'size', 'digest'))
over = 0
for i, l in enumerate(layers):
    size = l['size']
    flag = '  <-- OVER ${MAX_GB} GB' if size > max_bytes else ''
    if size > max_bytes:
        over += 1
    print('%3d %8.2f GB  %s%s' % (i, size / 1e9, l['digest'][:26], flag))

total = sum(l['size'] for l in layers)
print()
print('compressed total %.2f GB across %d layers; largest %.2f GB'
      % (total / 1e9, len(layers), max(l['size'] for l in layers) / 1e9))
if over:
    print()
    print('FAIL: %d layer(s) over ${MAX_GB} GB' % over)
    sys.exit(1)
"
fi
