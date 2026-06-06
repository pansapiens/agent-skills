# RCSB PDB Search API Reference

Find PDB IDs (or entity/assembly/instance IDs) by text, sequence, structure similarity, or chemical. Returns identifiers and optional metadata; use the Data API to fetch full records.

- **Tutorial:** [Search API: Understanding and Using](https://search.rcsb.org/index.html#search-api)
- **Reference:** [ReDoc](https://search.rcsb.org/redoc/index.html)
- **Query Editor:** [Query Editor](https://search.rcsb.org/query-editor.html)
- **Endpoint:** `https://search.rcsb.org/rcsbsearch/v2/query`

## Request shape

Search request is a JSON object:

| Context | Description |
|---------|-------------|
| `return_type` | Required. One of: `entry`, `assembly`, `polymer_entity`, `non_polymer_entity`, `polymer_instance`, `mol_definition` |
| `query` | Optional. Search expression (terminal + group nodes). Omit for count/facets only. |
| `request_options` | Optional. Pagination (`paginate`), `sort`, `scoring_strategy`, `return_counts`, `facets`, etc. |

## Return types

| return_type | Result format | Example |
|-------------|---------------|---------|
| `entry` | PDB IDs | `4HHB` |
| `assembly` | `[pdb_id]-[assembly_id]` | `4HHB-1` |
| `polymer_entity` | `[pdb_id]_[entity_id]` | `4HHB_1` |
| `polymer_instance` | `[pdb_id].[asym_id]` | `4HHB.A` |

## Query structure

- **Terminal node:** one search service (e.g. `text`, `sequence`) with `parameters`.
- **Group node:** combines nodes with `logical_operator`: `and` or `or`.

Example: text attribute search (X-ray, resolution &lt; 2.5 Å):

```json
{
  "query": {
    "type": "group",
    "logical_operator": "and",
    "nodes": [
      {
        "type": "terminal",
        "service": "text",
        "parameters": {
          "attribute": "exptl_crystal_grow.method",
          "operator": "contains_phrase",
          "value": "vapor diffusion"
        }
      },
      {
        "type": "terminal",
        "service": "text",
        "parameters": {
          "attribute": "rcsb_entry_info.resolution_combined",
          "operator": "less",
          "value": 2.5
        }
      }
    ]
  },
  "return_type": "entry",
  "request_options": {
    "paginate": {
      "start": 0,
      "rows": 20
    },
    "sort": [
      { "sort_by": "score", "direction": "desc" }
    ]
  }
}
```

## Search services (summary)

| Service | Use case |
|---------|----------|
| `text` | Attribute search (structure annotations). See [Structure Attributes](https://search.rcsb.org/structure-search-attributes.html). |
| `full_text` | Unstructured text across multiple fields. |
| `sequence` | Protein/DNA/RNA sequence (FASTA), MMseqs2, E-value or % identity. |
| `seqmotif` | Short motif (simple, PROSITE, or regex). |
| `structure` | 3D-embedding similarity (PDB ID or URL). |
| `strucmotif` | Structure motif (residue geometry). |
| `chemical` | Formula, SMILES, InChI, graph/fingerprint similarity. |

## Example: text attribute (experimental method)

```json
{
  "query": {
    "type": "terminal",
    "service": "text",
    "parameters": {
      "attribute": "exptl.method",
      "operator": "exact_match",
      "value": "X-RAY DIFFRACTION"
    }
  },
  "return_type": "entry",
  "request_options": {
    "paginate": { "start": 0, "rows": 10 }
  }
}
```

## Example: count only

```json
{
  "query": {},
  "return_type": "entry",
  "request_options": {
    "return_counts": true,
    "paginate": { "rows": 0 }
  }
}
```

## Example: sequence search (protein, 90% identity)

```json
{
  "query": {
    "type": "terminal",
    "service": "sequence",
    "parameters": {
      "evalue_cutoff": 1,
      "identity_cutoff": 0.9,
      "target": "pdb_protein_sequence",
      "value": "MTEYKLVVVGADGVGKSALTIQLIQNHFVDEYDPTIEDSYRKQVVIDGETCLLDILDTAGQEEY"
    }
  },
  "return_type": "polymer_entity",
  "request_options": {
    "scoring_strategy": "sequence",
    "paginate": { "start": 0, "rows": 20 }
  }
}
```

## Example: Search by UniProt accession

```json
{
  "query": {
    "type": "terminal",
    "service": "text",
    "parameters": {
      "attribute": "rcsb_polymer_entity_container_identifiers.reference_sequence_identifiers.database_accession",
      "operator": "exact_match",
      "value": "P01112"
    }
  },
  "return_type": "polymer_entity",
  "request_options": {
    "paginate": { "start": 0, "rows": 25 }
  }
}
```

## Calling the API

### GET (small requests)

Encode the JSON and pass as `json` query parameter:

```bash
# Minimal: return 5 entry IDs (match all)
QUERY='{"query":{},"return_type":"entry","request_options":{"paginate":{"rows":5}}}'
curl -s -G "https://search.rcsb.org/rcsbsearch/v2/query" --data-urlencode "json=$QUERY" | jq .
```

### POST (recommended)

```bash
curl -s -X POST "https://search.rcsb.org/rcsbsearch/v2/query" \
  -H "Content-Type: application/json" \
  -d '{"query":{},"return_type":"entry","request_options":{"paginate":{"rows":5}}}' | jq .
```

### Python

```python
import requests

SEARCH_URL = "https://search.rcsb.org/rcsbsearch/v2/query"

def search(query: dict) -> dict:
    r = requests.post(SEARCH_URL, json=query)
    r.raise_for_status()
    if r.status_code == 204:
        return {"result_set": [], "total_count": 0}
    return r.json()

# Get first 10 PDB IDs
result = search({
    "query": {},
    "return_type": "entry",
    "request_options": {"paginate": {"start": 0, "rows": 10}}
})
for hit in result.get("result_set", []):
    print(hit.get("identifier", hit))
```

## Response fields

- `total_count`: total matches.
- `result_set`: list of hits; each has `identifier` and optionally `score`, `services` (if verbose).
- `query_id`: echo of request query_id if sent.
- `facets`: present when faceting requested.

Empty result: HTTP 204 No Content.

## Pagination and limits

- Default `rows`: 10. Max in one request: 10,000.
- Use `start` and `rows` for paging. For very large result sets, prefer batching (e.g. 100–500 per request) and/or filters.

## Including computed structure models

In `request_options` set:

```json
"results_content_type": ["experimental", "computational"]
```

## Python client (rcsbsearchapi)

```bash
pip install rcsbsearchapi
```

```python
from rcsbsearchapi.search import TextQuery

q = TextQuery('"thymidine kinase"')
results = q("entry", rows=10)
# results is a list of PDB IDs
```

See [rcsbsearchapi](https://github.com/rcsb/rcsbsearchapi) for sequence, structure, and combined queries.
