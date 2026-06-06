# RCSB PDB Sequence Coordinates API Reference

Alignments between PDB/UniProt/RefSeq sequences and positional features (domains, sites, secondary structure) from UniProt, CATH, SCOPe, and RCSB PDB. Supports experimental structures and Computed Structure Models (CSMs).

- **Overview:** [Web APIs Overview – Sequence Coordinates](https://www.rcsb.org/docs/programmatic-access/web-apis-overview#sequence-coordinates-api)
- **Tutorial:** [Sequence Coordinates Server API](https://sequence-coordinates.rcsb.org/#sequence-coordinates-api)
- **GraphiQL:** [Interactive schema](https://sequence-coordinates.rcsb.org/graphiql/index.html)
- **Endpoint:** `https://sequence-coordinates.rcsb.org/graphql` (POST only)

## Sequence references

| SequenceReference | Identifier type | Example |
|-------------------|-----------------|---------|
| `NCBI_GENOME` | NCBI RefSeq chromosome | `NC_000001` |
| `NCBI_PROTEIN` | NCBI RefSeq protein | `NP_789765` |
| `UNIPROT` | UniProt accession | `P01112` |
| `PDB_ENTITY` | PDB entity ID / CSM entity ID | `2UZI_3`, `AF_AFP68871F1_1` |
| `PDB_INSTANCE` | PDB instance (chain) / CSM instance | `2UZI.C`, `AF_AFP68871F1.A` |

## Queries

1. **alignment(from, to, queryId, range?)** – alignments between two sequence databases.
2. **annotations(reference, queryId, sources, range?, filters?)** – positional features on a sequence.

Annotation `sources`: `UNIPROT`, `PDB_ENTITY`, `PDB_INSTANCE`.

## Alignment examples

### UniProt to PDB entities

Get PDB entities aligned to a UniProt accession, with coverage and aligned regions:

```graphql
query UniProt2PDB {
  alignments(
    from: UNIPROT
    to: PDB_ENTITY
    queryId: "P01112"
  ) {
    query_sequence
    target_alignments {
      target_id
      target_sequence
      coverage {
        query_coverage
        query_length
        target_coverage
        target_length
      }
      aligned_regions {
        query_begin
        query_end
        target_begin
        target_end
      }
    }
  }
}
```

### PDB instance to NCBI RefSeq proteins

```graphql
query PDBInstance2NCBI {
  alignments(
    from: PDB_INSTANCE
    to: NCBI_PROTEIN
    queryId: "4Z36.A"
  ) {
    query_sequence
    target_alignments {
      target_id
      target_sequence
      coverage { query_coverage target_coverage query_length target_length }
      aligned_regions { query_begin query_end target_begin target_end }
    }
  }
}
```

### CSM (AlphaFold) entity to NCBI protein

```graphql
query CSM2NCBI {
  alignments(
    from: PDB_ENTITY
    to: NCBI_PROTEIN
    queryId: "AF_AFP68871F1_1"
  ) {
    query_sequence
    target_alignments {
      target_id
      target_sequence
      coverage { query_coverage target_coverage query_length target_length }
      aligned_regions { query_begin query_end target_begin target_end }
    }
  }
}
```

### Genome (e.g. human chr1) to PDB entities

```graphql
query Genome2PDB {
  alignments(
    from: NCBI_GENOME
    to: PDB_ENTITY
    queryId: "NC_000001"
  ) {
    target_alignments {
      target_id
      orientation
      aligned_regions {
        query_begin
        query_end
        target_begin
        target_end
        exon_shift
      }
    }
  }
}
```

Note: `query_sequence` is null for genome-scale alignments. `exon_shift` handles codon boundaries at region ends.

## Annotations examples

### UniProt annotations on a PDB instance (chain)

```graphql
query PDBInstanceUniProtAnnotations {
  annotations(
    reference: PDB_INSTANCE
    sources: [UNIPROT]
    queryId: "2UZI.C"
  ) {
    target_id
    features {
      feature_id
      description
      name
      provenance_source
      type
      feature_positions {
        beg_ori_id
        beg_seq_id
        end_ori_id
        end_seq_id
      }
    }
  }
}
```

### Binding sites on genome (e.g. Chr1) from PDB instances

```graphql
query GenomePDBBindingSites {
  annotations(
    reference: NCBI_GENOME
    sources: [PDB_INSTANCE]
    queryId: "NC_000001"
    filters: [{
      field: TYPE
      operation: EQUALS
      values: "BINDING_SITE"
    }]
  ) {
    target_id
    features {
      feature_id
      type
      name
      feature_positions { beg_seq_id end_seq_id }
    }
  }
}
```

## Using variables (POST)

```json
{
  "query": "query Align($from: SequenceReference!, $to: SequenceReference!, $id: String!) { alignments(from: $from, to: $to, queryId: $id) { query_sequence target_alignments { target_id } } }",
  "variables": {
    "from": "UNIPROT",
    "to": "PDB_ENTITY",
    "id": "P01112"
  }
}
```

## Python helper

```python
import requests

SEQ_COORD_URL = "https://sequence-coordinates.rcsb.org/graphql"

def sequence_coordinates_query(query: str, variables: dict | None = None) -> dict:
    payload = {"query": query}
    if variables:
        payload["variables"] = variables
    r = requests.post(SEQ_COORD_URL, json=payload)
    r.raise_for_status()
    return r.json()

# UniProt -> PDB entities
result = sequence_coordinates_query("""
  query($id: String!) {
    alignments(from: UNIPROT, to: PDB_ENTITY, queryId: $id) {
      query_sequence
      target_alignments { target_id target_sequence }
    }
  }
""", {"id": "P01112"})
data = result.get("data", {})
if data and "alignments" in data:
    for ta in data["alignments"].get("target_alignments", []):
        print(ta["target_id"], ta.get("target_sequence", "")[:50])
```

## Response shape (alignment)

- **query_sequence:** Query sequence (null for genome).
- **target_alignments:** List of:
  - `target_id`, `target_sequence`
  - `coverage`: `query_coverage`, `query_length`, `target_coverage`, `target_length`
  - `aligned_regions`: `query_begin`, `query_end`, `target_begin`, `target_end`, optional `exon_shift`
  - `orientation`: 1 or -1 for genome (strand)

Positions are 1-based. Use `aligned_regions` to map residue indices between query and target.

## Response shape (annotations)

- Root is a list of objects with:
  - `target_id`
  - `features`: list of feature objects with `feature_id`, `type`, `name`, `description`, `provenance_source`, `feature_positions` (beg_seq_id, end_seq_id, beg_ori_id, end_ori_id, value).

Feature types follow the [controlled vocabulary](https://sequence-coordinates.rcsb.org/feature-type.html).
