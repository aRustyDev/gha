# Trust Check Actions

Security and trust validation for release pipelines.

## Overview

These actions implement trust validation to ensure:
- PRs come from authorized branches
- Actors are authorized maintainers
- Commits are cryptographically signed

## Actions

| Action | Description |
|--------|-------------|
| [validate-source-branch](./validate-source-branch.md) | Validate PR source branch patterns |
| [codeowners](./codeowners.md) | Verify actor in CODEOWNERS |
| [verify-signatures](./verify-signatures.md) | Verify commit signatures |

## Trust Model

```
┌─────────────────────────────────────────────────────────┐
│                    Trust Validation                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   │
│  │   Branch    │   │  CODEOWNERS │   │  Signature  │   │
│  │  Validation │   │   Check     │   │   Verify    │   │
│  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘   │
│         │                 │                 │          │
│         ▼                 ▼                 ▼          │
│  ┌─────────────────────────────────────────────────┐   │
│  │              All Checks Pass?                   │   │
│  └─────────────────────────┬───────────────────────┘   │
│                            │                           │
│              ┌─────────────┴─────────────┐            │
│              ▼                           ▼            │
│        ┌─────────┐                 ┌─────────┐        │
│        │  Allow  │                 │  Deny   │        │
│        │ Release │                 │ Release │        │
│        └─────────┘                 └─────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Usage Example

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      # Verify PR comes from allowed branch pattern
      - uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
        with:
          source-branch: ${{ github.head_ref }}
          allowed-pattern: "charts/*,feat/*,fix/*"
          denied-pattern: "main,release/*"

      # Verify actor is a maintainer
      - uses: arustydev/gha/actions/trust-check/codeowners@v1
        with:
          actor: ${{ github.actor }}
          paths: charts/${{ matrix.chart }}

      # Verify commits are signed
      - uses: arustydev/gha/actions/trust-check/verify-signatures@v1
        with:
          commit-range: origin/main..HEAD
          require-all: true
          verify-github: true
```

## Branch Validation Patterns

The `validate-source-branch` action supports glob patterns:

| Pattern | Matches |
|---------|---------|
| `feat/*` | `feat/add-login`, `feat/update-api` |
| `charts/*` | `charts/my-chart`, `charts/other-chart` |
| `release/v*` | `release/v1.0.0`, `release/v2.0.0` |

## CODEOWNERS Integration

The `codeowners` action parses GitHub's CODEOWNERS format:

```
# .github/CODEOWNERS
* @org/maintainers
/charts/ @org/chart-maintainers
/charts/critical-chart/ @org/senior-maintainers
```

## Signature Verification

The `verify-signatures` action recognizes:
- GPG signatures
- SSH signatures
- GitHub's web-flow signature (for web UI commits)

Trusted GitHub keys:
- `4AEE18F83AFDEB23` (github.com)
- `B5690EEEBB952194` (github.com)
