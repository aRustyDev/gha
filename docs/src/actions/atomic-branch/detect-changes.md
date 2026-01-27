# atomic-branch/detect-changes

Detect changed artifacts in commit range.

## Description

Compares commits against a base branch to identify which artifacts have been added, modified, or deleted. Outputs both space-separated lists (for shell scripts) and JSON arrays (for matrix strategies).

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact-path` | Yes | - | Path pattern for artifacts (e.g., `charts/*`) |
| `manifest-file` | Yes | - | Manifest file within each artifact |
| `target-branch` | No | `main` | Branch to compare against |
| `commit-range` | No | - | Explicit commit range (overrides target-branch) |
| `ignore-patterns` | No | - | Space-separated patterns to ignore |

## Outputs

| Output | Description |
|--------|-------------|
| `artifacts` | Space-separated list of all changed artifacts |
| `artifacts-json` | JSON array of all changed artifacts |
| `count` | Total number of changed artifacts |
| `new-artifacts` | Space-separated list of new artifacts |
| `new-artifacts-json` | JSON array of new artifacts |
| `modified-artifacts` | Space-separated list of modified artifacts |
| `modified-artifacts-json` | JSON array of modified artifacts |
| `deleted-artifacts` | Space-separated list of deleted artifacts |
| `deleted-artifacts-json` | JSON array of deleted artifacts |

## Usage

### Basic Detection

```yaml
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  id: changes
  with:
    artifact-path: charts/*
    manifest-file: Chart.yaml

- run: |
    echo "Changed: ${{ steps.changes.outputs.artifacts }}"
    echo "Count: ${{ steps.changes.outputs.count }}"
```

### Matrix Strategy

```yaml
jobs:
  detect:
    outputs:
      matrix: ${{ steps.changes.outputs.artifacts-json }}
    steps:
      - uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
        id: changes
        with:
          artifact-path: charts/*
          manifest-file: Chart.yaml

  process:
    needs: detect
    if: needs.detect.outputs.matrix != '[]'
    strategy:
      matrix:
        artifact: ${{ fromJson(needs.detect.outputs.matrix) }}
    steps:
      - run: echo "Processing ${{ matrix.artifact }}"
```

### Custom Commit Range

```yaml
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  with:
    artifact-path: crates/*
    manifest-file: Cargo.toml
    commit-range: "v1.0.0..HEAD"
```

### Ignore Patterns

```yaml
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  with:
    artifact-path: charts/*
    manifest-file: Chart.yaml
    ignore-patterns: "charts/deprecated-* charts/internal-*"
```

## Detection Logic

1. Get list of changed files in commit range
2. Extract artifact directories from paths
3. Filter to artifacts with valid manifest files
4. Categorize as new/modified/deleted
5. Output in multiple formats

## Requirements

- Repository must be checked out with `fetch-depth: 0` for full history
- Manifest file must exist for artifact to be detected
