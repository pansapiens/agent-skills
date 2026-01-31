#!/bin/bash
# Get the digest of a Docker image for use in OCI labels or Dockerfile pinning.
# Requires: docker, python3

set -euo pipefail

PLATFORM=""

usage() {
    echo "Usage: $0 [--platform <platform>] <image>"
    echo ""
    echo "Get the digest (SHA256) of a Docker image."
    echo ""
    echo "Options:"
    echo "  --platform <platform>  Specify platform (e.g., linux/amd64, linux/arm64)"
    echo "                         Default: first available (typically linux/amd64)"
    echo ""
    echo "Examples:"
    echo "  $0 python:3.12-slim"
    echo "  $0 --platform linux/arm64 python:3.12-slim"
    echo "  $0 node:20-alpine"
    echo ""
    echo "Output can be used for:"
    echo "  - Dockerfile pinning: FROM python:3.12-slim@sha256:..."
    echo "  - OCI labels: org.opencontainers.image.base.digest"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --platform)
            if [[ -z "${2:-}" ]]; then
                echo "Error: --platform requires a value" >&2
                exit 1
            fi
            PLATFORM="$2"
            shift 2
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
    echo "Usage: $0 [--platform <platform>] <image>" >&2
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo "Error: docker is not installed or not in PATH" >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is not installed or not in PATH" >&2
    exit 1
fi

DIGEST=$(docker manifest inspect "${IMAGE}" -v 2>/dev/null | python3 -c "
import sys, json

platform_filter = '${PLATFORM}'
data = json.load(sys.stdin)

# Handle both single manifest and manifest list (array)
if isinstance(data, list):
    if platform_filter:
        # Parse platform filter (e.g., 'linux/amd64' -> os='linux', arch='amd64')
        parts = platform_filter.split('/')
        target_os = parts[0] if len(parts) > 0 else ''
        target_arch = parts[1] if len(parts) > 1 else ''
        target_variant = parts[2] if len(parts) > 2 else ''
        
        for item in data:
            desc = item.get('Descriptor', {})
            plat = desc.get('platform', {})
            os_match = plat.get('os', '') == target_os if target_os else True
            arch_match = plat.get('architecture', '') == target_arch if target_arch else True
            variant_match = plat.get('variant', '') == target_variant if target_variant else True
            
            if os_match and arch_match and (not target_variant or variant_match):
                print(desc.get('digest', ''))
                sys.exit(0)
        # Platform not found
        print('', end='')
    else:
        # Get first architecture's digest (typically amd64)
        print(data[0].get('Descriptor', {}).get('digest', ''))
else:
    print(data.get('Descriptor', {}).get('digest', ''))
" 2>/dev/null)

if [[ -z "${DIGEST}" ]]; then
    if [[ -n "${PLATFORM}" ]]; then
        echo "Error: Could not get digest for image '${IMAGE}' on platform '${PLATFORM}'" >&2
        echo "Make sure the image exists for that platform." >&2
    else
        echo "Error: Could not get digest for image '${IMAGE}'" >&2
        echo "Make sure the image exists and you have access to it." >&2
    fi
    exit 1
fi

echo "${DIGEST}"
