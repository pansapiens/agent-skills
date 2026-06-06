# RCSB PDB Structure Alignment API Reference

Pairwise (or list) structure alignment: superposition, RMSD, TM-score, and sequence alignment derived from 3D. Submit a job, poll by ticket, then read results. Supports PDB IDs, URLs, or uploaded files.

- **User guide:** [Alignment API](https://alignment.rcsb.org/)
- **API Reference:** [Alignment API Reference](https://alignment.rcsb.org/api-reference.html)
- **Query Editor:** [Query Editor](https://alignment.rcsb.org/query-editor.html)
- **Base URL:** `https://alignment.rcsb.org/api/v1/structures`

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/submit` | GET or POST | Submit alignment job; returns job ticket (UUID). |
| `/results?uuid={ticket}` | GET | Poll status and retrieve results. |

POST is required when uploading structure files. Use `multipart/form-data` with `query` and optional `files`.

## Algorithms

| Method | Description |
|--------|-------------|
| `fatcat-rigid` | Rigid-body (jFATCAT-rigid). |
| `fatcat-flexible` | Flexible (jFATCAT-flexible), twists between regions. |
| `ce` | Rigid (jCE). |
| `ce-cp` | Circular permutations (jCE-CP). |
| `tmalign` | Sequence-independent, TM-score. |
| `smith-waterman-3d` | Sequence-based (Blosum65), faster, needs sequence similarity. |

Atoms used for fitting: C-alpha only; first model; first alternate conformation; first residue in microheterogeneity. Each structure must have at least 10 C-alpha residues.

## Submit request (pairwise by PDB ID)

Query body (JSON) for two chains:

```json
{
  "context": {
    "mode": "pairwise",
    "method": { "name": "fatcat-rigid" },
    "structures": [
      { "entry_id": "8HSK", "selection": { "asym_id": "A" } },
      { "entry_id": "8HSF", "selection": { "asym_id": "A" } }
    ]
  }
}
```

Supported `method.name`: `fatcat-rigid`, `fatcat-flexible`, `ce`, `ce-cp`, `tmalign`, `smith-waterman-3d`.

## Submit with chain selection

```json
{
  "context": {
    "mode": "pairwise",
    "method": { "name": "tmalign" },
    "structures": [
      { "entry_id": "1TAD", "selection": { "asym_id": "A" } },
      { "entry_id": "121P", "selection": { "asym_id": "A" } }
    ]
  }
}
```

Omit `selection` to use all chains (first model). Use `asym_id` for label_asym_id (e.g. `"A"`, `"B"`).

## Submit with uploaded file

One structure by PDB ID, one from file. Files appear in the same order as in `structures`; the file placeholder uses `"format"` instead of `"entry_id"`:

```json
{
  "context": {
    "mode": "pairwise",
    "method": { "name": "fatcat-rigid" },
    "structures": [
      { "entry_id": "8HSK", "selection": { "asym_id": "A" } },
      { "format": "mmcif", "selection": { "asym_id": "A" } }
    ]
  }
}
```

Form data: `query` = JSON string; `files` = file part(s) in order (e.g. `open("file.cif", "rb")`). Formats: mmCIF, bcif, PDB; gzip allowed.

## Submit via GET

Encode the query and send as GET parameter:

```
https://alignment.rcsb.org/api/v1/structures/submit?query=<url-encoded-json>
```

## Poll for results

```
GET https://alignment.rcsb.org/api/v1/structures/results?uuid={ticket}
```

Responses:

- **RUNNING:** `{"info": {"uuid": "...", "status": "RUNNING"}}` — poll again.
- **ERROR:** `{"info": {"uuid": "...", "status": "ERROR", "message": "..."}}`.
- **COMPLETE:** Full result payload in the same response (see below).

Poll every 2–5 seconds until status is `COMPLETE` or `ERROR`.

## Result structure (COMPLETE)

Top-level: `info`, `meta`, `results`.

- **meta:** `alignment_mode`, `alignment_method`.
- **results:** Array of alignment objects. For pairwise, each has:
  - **structures:** [reference, aligned] (e.g. two items with `entry_id` and `selection`).
  - **structure_alignment:** Blocks (rigid/flexible). Each block:
    - **regions:** Per-structure lists of `{asym_id, beg_seq_id, beg_index, length}`.
    - **transformations:** 4×4 matrices (column-major).
    - **summary:** e.g. `scores` (type: RMSD, similarity-score, etc.), `n_aln_residue_pairs`.
  - **sequence_alignment:** Per-structure `sequence` and `regions` (and `gaps` if any).
  - **summary:** Overall `scores` (e.g. sequence-similarity, sequence-identity, similarity-score, TM-score, RMSD), `n_aln_residue_pairs`, `aln_coverage`, etc.

Example summary scores:

```json
"summary": {
  "scores": [
    { "value": 1, "type": "sequence-similarity" },
    { "value": 1, "type": "sequence-identity" },
    { "value": 46.7, "type": "similarity-score" },
    { "value": 0.23, "type": "TM-score" },
    { "value": 0.99, "type": "RMSD" }
  ],
  "n_aln_residue_pairs": 20,
  "aln_coverage": [95, 100]
}
```

## Python: submit and poll

```python
import json
import time
import requests

BASE = "https://alignment.rcsb.org/api/v1/structures"

def submit_pairwise(entry1: str, entry2: str, asym1: str = "A", asym2: str = "A", method: str = "fatcat-rigid") -> str:
    query = {
        "context": {
            "mode": "pairwise",
            "method": {"name": method},
            "structures": [
                {"entry_id": entry1, "selection": {"asym_id": asym1}},
                {"entry_id": entry2, "selection": {"asym_id": asym2}},
            ],
        }
    }
    r = requests.post(f"{BASE}/submit", data={"query": json.dumps(query)})
    r.raise_for_status()
    return r.json()["uuid"]

def get_results(uuid: str) -> dict:
    r = requests.get(f"{BASE}/results", params={"uuid": uuid})
    r.raise_for_status()
    return r.json()

def align_and_wait(entry1: str, entry2: str, **kwargs) -> dict:
    uuid = submit_pairwise(entry1, entry2, **kwargs)
    while True:
        data = get_results(uuid)
        status = data.get("info", {}).get("status")
        if status == "COMPLETE":
            return data
        if status == "ERROR":
            raise RuntimeError(data.get("info", {}).get("message", "Alignment failed"))
        time.sleep(2)
```

## Python: submit with file upload

```python
def submit_with_file(entry_id: str, filepath: str, method: str = "fatcat-rigid") -> str:
    query = {
        "context": {
            "mode": "pairwise",
            "method": {"name": method},
            "structures": [
                {"entry_id": entry_id, "selection": {"asym_id": "A"}},
                {"format": "mmcif", "selection": {"asym_id": "A"}},
            ],
        }
    }
    with open(filepath, "rb") as f:
        r = requests.post(
            f"{BASE}/submit",
            data={"query": json.dumps(query)},
            files=[("files", (os.path.basename(filepath), f))],
        )
    r.raise_for_status()
    return r.json()["uuid"]
```

## Errors

- **400 Bad Request:** Invalid query JSON or structure.
- **500 Internal Server Error:** Server error on submit.
- **200 + status ERROR:** Job failed; see `info.message`.

## File formats

Accepted: PDBx/mmCIF, BinaryCIF, legacy PDB. Optional gzip (e.g. `.cif.gz`). For file-based structures, set `format` to `mmcif`, `bcif`, or `pdb` as appropriate.
