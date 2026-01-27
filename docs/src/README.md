# aRustyDev/gha

Reusable GitHub Actions and workflows for CI/CD automation.

## Overview

This repository provides a library of composite GitHub Actions designed for:

- **Attestation management** - SLSA provenance and build attestations
- **Atomic releases** - Per-artifact branching and release automation
- **Version management** - Semantic versioning from conventional commits
- **Changelog generation** - Keep-a-Changelog format with git-cliff
- **Trust validation** - CODEOWNERS, signatures, and branch policies
- **Workflow orchestration** - Cross-repository dispatch and coordination

## Quick Start

### Using an Action

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  with:
    file-path: ./my-artifact.tar.gz
```

### Using a Reusable Workflow

```yaml
jobs:
  validate:
    uses: arustydev/gha/.github/workflows/validate-contribution.yml@v1
    with:
      artifact-path: "charts/*"
```

## Design Principles

1. **Composable** - Small, focused actions that combine into workflows
2. **Portable** - No assumptions about repository structure
3. **Observable** - Rich outputs for debugging and downstream use
4. **Secure** - Attestation-backed provenance chain

## Categories

| Category | Purpose |
|----------|---------|
| [Attestation](./actions/attestation/index.md) | SLSA provenance and attestation management |
| [Atomic Branch](./actions/atomic-branch/index.md) | Per-artifact branch and PR automation |
| [Version Bump](./actions/version-bump/index.md) | Semantic versioning from commits |
| [Changelog](./actions/changelog/index.md) | Changelog generation and extraction |
| [Trust Check](./actions/trust-check/index.md) | Trust validation and verification |
| [Source PR](./actions/source-pr/index.md) | PR discovery and lineage tracking |
| [Dispatch](./actions/dispatch/index.md) | Cross-repository workflow triggers |

## License

MIT
