# Atomic Branch Actions

Per-artifact branch and PR creation for atomic releases.

## Overview

These actions implement the "atomic branching" pattern where each artifact (chart, package, module) gets its own dedicated branch and PR for release. This enables:

- **Independent releases** - Each artifact can be released on its own schedule
- **Isolated validation** - Per-artifact CI checks and approvals
- **Attestation lineage** - Track provenance from source to release

## Actions

| Action | Description |
|--------|-------------|
| [detect-changes](./detect-changes.md) | Detect changed artifacts in commit range |
| [create-branch](./create-branch.md) | Create artifact-specific branches |
| [create-pr](./create-pr.md) | Create PRs with attestation lineage |

## Workflow Pattern

```
┌──────────────────┐
│  Source PR       │  (e.g., feat: add feature to chart-a)
│  → integration   │
└────────┬─────────┘
         │ merge
         ▼
┌──────────────────┐
│  detect-changes  │  Finds: chart-a modified
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  create-branch   │────▶│  charts/chart-a  │
│  (per artifact)  │     │  branch created  │
└────────┬─────────┘     └──────────────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  create-pr       │────▶│  PR: chart-a     │
│  (with lineage)  │     │  → main          │
└──────────────────┘     └──────────────────┘
```

## Usage Example

```yaml
name: Atomize Changes

on:
  push:
    branches: [integration]

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
          artifact-path: charts/*
          manifest-file: Chart.yaml

  atomize:
    needs: detect
    if: needs.detect.outputs.count > 0
    strategy:
      matrix:
        artifact: ${{ fromJson(needs.detect.outputs.artifacts) }}
    steps:
      - uses: actions/checkout@v4

      - uses: arustydev/gha/actions/atomic-branch/create-branch@v1
        id: branch
        with:
          artifact: ${{ matrix.artifact }}
          artifact-path: charts

      - uses: arustydev/gha/actions/atomic-branch/create-pr@v1
        with:
          artifact: ${{ matrix.artifact }}
          branch: ${{ steps.branch.outputs.branch }}
          source-pr: ${{ github.event.head_commit.message }}
```

## Key Concepts

### Artifact Detection

The `detect-changes` action compares commits against a base branch to find:
- **New artifacts** - Directories that didn't exist before
- **Modified artifacts** - Changes to existing artifact files
- **Deleted artifacts** - Removed artifact directories

### Branch Naming

Branches follow the pattern: `{prefix}/{artifact-name}`

Examples:
- `charts/my-chart`
- `crates/my-crate`
- `packages/my-package`

### Attestation Lineage

The `create-pr` action carries forward attestation maps from source PRs, creating a verifiable chain:

```
Source PR attestations  →  Atomic PR attestations  →  Release attestations
```
