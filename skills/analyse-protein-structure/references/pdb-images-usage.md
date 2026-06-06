# PDB Images Visualization Guide

## Installation

PDB images is a Node.js tool for generating visualizations of protein structures.

```bash
# Install globally
npm install -g pdb-images

# Or use npx without installation
npx pdb-images --help
```

## Basic Usage

### Default Images

Generate all default image types for a structure:

```bash
npx pdb-images structure.pdb --output-dir images/
```

This generates:
- Entry overview image
- Assembly image (if biological assembly exists)
- Chain entity images

### Multiple Views

Specify different rotation angles/views:

```bash
npx pdb-images structure.pdb --output-dir images/ --views front,side,top,bottom
```

Available views:
- `front` - Front-facing view
- `side` - Side view
- `top` - Top-down view
- `bottom` - Bottom-up view

### Image Types

Generate specific image types:

```bash
npx pdb-images structure.pdb --output-dir images/ --types ligand,domain
```

Available types:
- `entry` - Overall structure overview
- `assembly` - Biological assembly
- `entity` - Chain-level visualization
- `ligand` - Ligand binding sites
- `domain` - Structural domains
- `modres` - Modified residues
- `bfactor` - B-factor coloring
- `validation` - Validation information

### AlphaFold Predictions

For AlphaFold mmCIF files with pLDDT confidence scores:

```bash
npx pdb-images structure.cif --mode alphafold --output-dir images/
```

This adds pLDDT confidence coloring to images.

## Complete Examples

### Example 1: Contact Analysis Visualization

Generate images highlighting interacting chains:

```bash
# After contact analysis between chains A and B
npx pdb-images complex.pdb \
  --output-dir results/images/ \
  --views front,side,top \
  --types entry,assembly,ligand
```

### Example 2: Ligand Binding Site

Focus on ligand binding sites:

```bash
npx pdb-images complex.pdb \
  --output-dir results/ligand_images/ \
  --types ligand,domain \
  --views front,side
```

### Example 3: AlphaFold Structure

Visualize AlphaFold prediction with confidence:

```bash
npx pdb-images AF_P00533-F1-model_v4.cif \
  --mode alphafold \
  --output-dir alphafold_images/
```

### Example 4: Multi-Chain Complex

Generate images for each chain in a complex:

```bash
npx pdb-images multimer.pdb \
  --output-dir chain_images/ \
  --types entity,assembly \
  --views front,side,top
```

## Troubleshooting

### Large Files

For large structures (membrane proteins, ribosomes):

```bash
# Increase timeout (if supported)
npx pdb-images large_structure.pdb \
  --output-dir images/ \
  --timeout 300
```

### Missing Images

If no images are generated:

1. Check file format (must be .pdb or .cif)
2. Verify structure is valid (no missing atoms, complete headers)
3. Check output directory permissions
4. Try different image types

### Node.js Issues

If `npm` or `npx` is not found:

```bash
# Install Node.js from: https://nodejs.org/

# Verify installation
node --version
npm --version
npx --version
```

## Batch Processing

Generate images for multiple structures:

```bash
for pdb_file in data/*.pdb; do
    basename=$(basename "$pdb_file" .pdb)
    npx pdb-images "$pdb_file" \
      --output-dir "images/$basename" \
      --views front,side,top \
      --types entry,assembly
done
```

## Advanced Options

See full help for all options:

```bash
npx pdb-images --help
```

Common advanced options:
- `--resolution` - Set image resolution
- `--width`/`--height` - Custom dimensions
- `--no-water` - Exclude water molecules
- `--colormap` - Color scheme for pLDDT/B-factor
