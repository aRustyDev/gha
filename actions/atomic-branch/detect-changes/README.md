# atomic-branch/detect-changes

Detect changed artifacts in a commit range for atomic branch processing.

This action compares the current branch against a target branch to identify which artifacts (charts, crates, packages) have changes that need processing. It categorizes changes as new, modified, or deleted.

## Usage

```yaml
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  id: changes
  with:
    artifact-path: charts
    manifest-file: Chart.yaml
    target-branch: main

- run: echo "Changed: ${{ steps.changes.outputs.artifacts }}"

# Use in matrix strategy
jobs:
  process:
    needs: detect
    strategy:
      matrix:
        artifact: ${{ fromJson(needs.detect.outputs.artifacts-json) }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact-path` | Yes | - | Path to artifacts directory (e.g., "charts", "crates") |
| `manifest-file` | Yes | - | Manifest file within each artifact (e.g., "Chart.yaml", "Cargo.toml") |
| `target-branch` | No | `main` | Branch to compare against |
| `commit-range` | No | - | Explicit commit range (overrides target-branch comparison) |
| `ignore-patterns` | No | - | Patterns to ignore (space-separated globs) |

## Outputs

| Output | Description |
|--------|-------------|
| `artifacts` | Space-separated list of all changed artifact names |
| `artifacts-json` | JSON array of all changed artifacts (for matrix) |
| `count` | Number of changed artifacts |
| `new-artifacts` | Space-separated list of new artifact names |
| `new-artifacts-json` | JSON array of new artifacts |
| `modified-artifacts` | Space-separated list of modified artifact names |
| `modified-artifacts-json` | JSON array of modified artifacts |
| `deleted-artifacts` | Space-separated list of deleted artifact names |
| `deleted-artifacts-json` | JSON array of deleted artifacts |

## Examples

### Basic usage

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0

  - uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
    id: changes
    with:
      artifact-path: charts
      manifest-file: Chart.yaml
      target-branch: main

  - if: steps.changes.outputs.count != '0'
    run: |
      echo "Changed charts: ${{ steps.changes.outputs.artifacts }}"
      echo "New charts: ${{ steps.changes.outputs.new-artifacts }}"
      echo "Modified charts: ${{ steps.changes.outputs.modified-artifacts }}"
```

### Using explicit commit range

```yaml
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  id: changes
  with:
    artifact-path: crates
    manifest-file: Cargo.toml
    commit-range: "HEAD~5..HEAD"
```

### With ignore patterns

```yaml
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  id: changes
  with:
    artifact-path: charts
    manifest-file: Chart.yaml
    ignore-patterns: "test-* deprecated-*"
```

### Matrix strategy for processing

```yaml
jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      artifacts: ${{ steps.changes.outputs.artifacts-json }}
      count: ${{ steps.changes.outputs.count }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
        id: changes
        with:
          artifact-path: charts
          manifest-file: Chart.yaml

  process:
    needs: detect
    if: needs.detect.outputs.count != '0'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        artifact: ${{ fromJson(needs.detect.outputs.artifacts) }}
      fail-fast: false
    steps:
      - run: echo "Processing ${{ matrix.artifact }}"
```

## Prerequisites

- Repository must be checked out with full history (`fetch-depth: 0`)
- Target branch must exist in the repository
- `jq` must be available (included in GitHub-hosted runners)

## How it works

1. Determines the commit range based on `target-branch` or explicit `commit-range`
2. Uses `git diff --name-only` to get changed files
3. Filters files to the specified `artifact-path`
4. Extracts unique artifact directory names
5. Validates each artifact has the required `manifest-file`
6. Categorizes artifacts as new, modified, or deleted
7. Outputs results in both space-separated and JSON formats
