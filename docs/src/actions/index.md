# GitHub Actions

Reusable composite actions for attestation-backed release pipelines.

## Categories

| Category | Actions | Description |
|----------|---------|-------------|
| [Attestation](./attestation/index.md) | 5 | Cryptographic attestation management |
| [Atomic Branch](./atomic-branch/index.md) | 3 | Per-artifact branch and PR creation |
| [Version Bump](./version-bump/index.md) | 3 | Semantic versioning automation |
| [Changelog](./changelog/index.md) | 3 | Changelog generation and management |
| [Trust Check](./trust-check/index.md) | 3 | Security and trust validation |
| [Source PR](./source-pr/index.md) | 1 | PR discovery from commits |
| [Dispatch](./dispatch/index.md) | 1 | Workflow event triggering |

## Quick Reference

### Attestation Pipeline

```yaml
# Generate attestation for artifact
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    file-path: dist/my-package.tar.gz

- uses: arustydev/gha/actions/attestation/create@v1
  with:
    subject-name: my-package
    subject-digest: ${{ steps.digest.outputs.digest }}
```

### Atomic Release Flow

```yaml
# Detect changes and create per-artifact PRs
- uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
  id: changes
  with:
    artifact-path: charts/*
    manifest-file: Chart.yaml

- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    artifact: ${{ matrix.artifact }}
    branch: charts/${{ matrix.artifact }}
```

### Version Management

```yaml
# Determine and apply version bump
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-chart
    artifact-path: charts

- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: version
  with:
    current-version: ${{ steps.current.outputs.version }}
    bump-type: ${{ steps.bump.outputs.bump-type }}
```

## Design Principles

1. **Composable** - Actions can be combined in any order
2. **Shell-based** - Pure bash for portability (no Node.js dependencies)
3. **Attestation-native** - Built-in support for SLSA provenance
4. **Idempotent** - Safe to re-run without side effects
