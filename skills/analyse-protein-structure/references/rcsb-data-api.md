# RCSB PDB Data API Reference

Retrieve metadata and annotations when you already have a PDB ID or CSM ID. Use for title, experimental method, entities, assemblies, sequences, citations, chemical components, and cross-references.

- **Tutorial:** [Data API: Understanding and Using](https://data.rcsb.org/index.html)
- **REST API Reference:** [ReDoc](https://data.rcsb.org/redoc/index.html)
- **GraphQL endpoint:** `https://data.rcsb.org/graphql`
- **GraphiQL:** [Interactive schema](https://data.rcsb.org/graphql/index.html)

## Data hierarchy and identifiers

| Level | Identifier format | Example |
|-------|-------------------|---------|
| Entry | `[pdb_id]` or CSM ID | `4HHB`, `AF_AFP68871F1` |
| Polymer entity | `[entry_id]_[entity_id]` | `4HHB_1`, `2CPK_1` |
| Entity instance (chain) | `[entry_id].[asym_id]` | `4HHB.A`, `4HHB.B` |
| Assembly | `[entry_id]-[assembly_id]` | `4HHB-1` |

REST base path: `https://data.rcsb.org/rest/v1/core/<resource>/<ids...>`.

## REST examples

### Entry (title and method)

```bash
curl -s "https://data.rcsb.org/rest/v1/core/entry/4HHB" | jq .
```

Returns full entry JSON (struct, exptl, etc.). For multiple entries use the batch endpoint or GraphQL.

### Polymer entity (single)

```bash
curl -s "https://data.rcsb.org/rest/v1/core/polymer_entity/4HHB/1" | jq .
```

### Polymer entity instance (chain)

```bash
curl -s "https://data.rcsb.org/rest/v1/core/polymer_entity_instance/4HHB/A" | jq .
```

## GraphQL examples

All requests go to `https://data.rcsb.org/graphql`. Prefer POST with JSON body for complex queries.

### Entry: title and experimental method

```graphql
query {
  entry(entry_id: "4HHB") {
    exptl { method }
  }
}
```

Multiple entries:

```graphql
query {
  entries(entry_ids: ["4HHB", "12CA", "3PQR"]) {
    rcsb_id
    struct { title }
    exptl { method }
  }
}
```

### Primary citation and release date

```graphql
query {
  entries(entry_ids: ["1STP", "2JEF", "1CDG"]) {
    rcsb_id
    rcsb_accession_info { initial_release_date }
    audit_author { name }
    rcsb_primary_citation {
      pdbx_database_id_PubMed
      pdbx_database_id_DOI
    }
  }
}
```

### Polymer entities: taxonomy and cluster membership

```graphql
query {
  polymer_entities(entity_ids: ["2CPK_1", "3WHM_1", "2D5Z_1"]) {
    rcsb_id
    rcsb_entity_source_organism {
      ncbi_taxonomy_id
      ncbi_scientific_name
    }
    rcsb_cluster_membership { cluster_id, identity }
  }
}
```

### Polymer entity instances: domain annotations

```graphql
query {
  polymer_entity_instances(instance_ids: ["4HHB.A", "12CA.A", "3PQR.A"]) {
    rcsb_id
    rcsb_polymer_instance_annotation {
      annotation_id
      name
      type
    }
  }
}
```

### Traversing hierarchy: entity + entry

```graphql
query {
  polymer_entity(entry_id: "4HHB", entity_id: "1") {
    rcsb_entity_source_organism { ncbi_scientific_name }
    entry {
      exptl { method }
    }
  }
}
```

### Assemblies

```graphql
query {
  assemblies(assembly_ids: ["4HHB-1", "12CA-1"]) {
    rcsb_assembly_info {
      entry_id
      assembly_id
      polymer_entity_instance_count
    }
  }
}
```

### Reference sequence identifiers (UniProt, etc.)

```graphql
query {
  entries(entry_ids: ["7NHM", "5L2G"]) {
    polymer_entities {
      rcsb_id
      rcsb_polymer_entity_container_identifiers {
        reference_sequence_identifiers {
          database_accession
          database_name
        }
      }
    }
  }
}
```

## Python: GraphQL with requests

```python
import requests

DATA_GRAPHQL = "https://data.rcsb.org/graphql"

def data_api_graphql(query: str, variables: dict | None = None) -> dict:
    payload = {"query": query}
    if variables:
        payload["variables"] = variables
    r = requests.post(DATA_GRAPHQL, json=payload)
    r.raise_for_status()
    return r.json()

# Example: entry title and method
response = data_api_graphql("""
  query($id: String!) {
    entry(entry_id: $id) {
      struct { title }
      exptl { method }
    }
  }
""", {"id": "4HHB"})
print(response["data"]["entry"])
```

## Python client (rcsb-api)

Official client: [py-rcsb-api](https://github.com/rcsb/py-rcsb-api). Use `rcsbapi.data` for Data API.

```bash
pip install rcsb-api
```

```python
from rcsbapi.data import DataApi

data_api = DataApi()
# Single entry
entry = data_api.get_entry("4HHB")
# Multiple entries
entries = data_api.get_entries(["4HHB", "12CA"])
```

## Usage notes

- **Batch size:** Prefer batching IDs (e.g. up to hundreds) rather than thousands in one request.
- **Caching:** Cache responses when repeating over the same IDs within a release cycle.
- **404:** Invalid or obsolete ID returns 404. GraphQL returns 200 with `errors` or null data for bad requests.
- **REST vs GraphQL:** Use REST for “full object” fetches; use GraphQL when you need specific fields or cross-level data in one call.
