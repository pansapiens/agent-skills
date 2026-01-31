# OCI Image Spec Annotations

OCI Image Spec annotations are a way to add metadata to a Docker image via the `LABEL` directive.

## Rules

- Annotations MUST be a key-value map where both the key and value MUST be strings.
- While the value MUST be present, it MAY be an empty string.
- Keys MUST be unique within this map, and best practice is to namespace the keys.
- Keys SHOULD be named using a reverse domain notation - e.g. `com.example.myKey`.
- The prefix `org.opencontainers` is reserved for keys defined in Open Container Initiative (OCI) specifications and MUST NOT be used by other specifications and extensions.
- Keys using the `org.opencontainers.image` namespace are reserved for use in the OCI Image Specification and MUST NOT be used by other specifications and extensions, including other OCI specifications.
- If there are no annotations then this property MUST either be absent or be an empty map.

## Pre-Defined Annotation Keys for LABELs

- `LABEL org.opencontainers.image.created=...` — Date and time on which the image was built, conforming to RFC 3339 / ISO 8601. Generate value with: `date -u +%Y-%m-%dT%H:%M:%SZ`
- `LABEL org.opencontainers.image.authors=...` — Contact details of the people or organization responsible for the _image_ (freeform string). This is often NOT the same as the AUTHORS of the software packaged in the image.
- `LABEL org.opencontainers.image.url=...` — URL to find more information on the image (string).
- `LABEL org.opencontainers.image.documentation=...` — URL to get documentation on the image (string).
- `LABEL org.opencontainers.image.source=...` — URL to get source code for building the image (string). In practice, often from `$GIT_REPO`.
- `LABEL org.opencontainers.image.version=...` — Version of the packaged software (e.g. semantic version from the repo, or git commit hash).
  - The version MAY match a label or tag in the source code repository.
  - Version MAY be [Semantic versioning-compatible](https://semver.org/).
- `LABEL org.opencontainers.image.revision=...` — Source control revision identifier for the packaged software. In practice, often from `$GIT_REF`.
- `LABEL org.opencontainers.image.vendor=...` — Name of the distributing entity, organization or individual. Unless otherwise specified by the user, the default is: `containerbot`.
- `LABEL org.opencontainers.image.licenses=...` — License(s) under which contained software is distributed as an [SPDX License Expression](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/).
- `LABEL org.opencontainers.image.ref.name=...` — Name of the reference for a target (string).
  - SHOULD only be considered valid when on descriptors on `index.json` within [image layout](image-layout.md).
  - Character set of the value SHOULD conform to alphanum of `A-Za-z0-9` and separator set of `-._:@/+`
  - A valid reference matches the following [grammar](considerations.md#ebnf):

    ```ebnf
    ref       ::= component ("/" component)*
    component ::= alphanum (separator alphanum)*
    alphanum  ::= [A-Za-z0-9]+
    separator ::= [-._:@+] | "--"
    ```

- `LABEL org.opencontainers.image.title=...` — Human-readable title of the image (string).
- `LABEL org.opencontainers.image.description=...` — Human-readable description of the software packaged in the image (string).
- `LABEL org.opencontainers.image.base.digest=...` — [Digest](descriptor.md#digests) of the image this image is based on (string). Use the `get_docker_image_digest.sh` script to obtain the value.
  - This SHOULD be the immediate image sharing zero-indexed layers with the image, such as from a Dockerfile `FROM` statement.
  - This SHOULD NOT reference any other images used to generate the contents of the image (e.g., multi-stage Dockerfile builds).
- `LABEL org.opencontainers.image.base.name=...` — Image reference of the image this image is based on (string). In practice, take from `FROM <base-image>` in the Dockerfile.
  - This SHOULD be a fully qualified reference name, without any assumed default registry. (e.g., `registry.example.com/my-org/my-image:tag` instead of `my-org/my-image:tag`).
  - This SHOULD be the immediate image sharing zero-indexed layers with the image, such as from a Dockerfile `FROM` statement.
  - This SHOULD NOT reference any other images used to generate the contents of the image (e.g., multi-stage Dockerfile builds).
  - If the `image.base.name` annotation is specified, the `image.base.digest` annotation SHOULD be the digest of the manifest referenced by the `image.ref.name` annotation.
- `LABEL org.opencontainers.image.usage=...` — Usage of the image, e.g. `docker run -it --gpus all --rm <image> <command>`. Out-of-spec annotation but often included in the wild, so we include it.
