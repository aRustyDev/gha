# Attestation Actions

Cryptographic attestation management for supply chain security.

## Overview

These actions implement [SLSA](https://slsa.dev/) provenance attestations using GitHub's built-in attestation infrastructure. They manage attestation maps embedded in PR descriptions to track the chain of trust through multi-stage pipelines.

## Actions

| Action | Description |
|--------|-------------|
| [extract-map](./extract-map.md) | Extract attestation map from PR description |
| [generate-digest](./generate-digest.md) | Generate cryptographic digest for subjects |
| [update-pr-map](./update-pr-map.md) | Update PR description with attestation entry |
| [verify-chain](./verify-chain.md) | Verify complete attestation chain |
| [create](./create.md) | Create attestation (wrapper for attest-build-provenance) |

## Attestation Map Format

Attestation maps are stored in PR descriptions using HTML comments:

```html
<!-- ATTESTATION_MAP_START -->
```json
{
  "lint-check": "sha256:abc123...",
  "test-check": "sha256:def456...",
  "build-check": "sha256:789ghi..."
}
```
<!-- ATTESTATION_MAP_END -->
```

## Pipeline Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   PR Open   │───▶│  Lint/Test  │───▶│   Build     │
└─────────────┘    └──────┬──────┘    └──────┬──────┘
                          │                   │
                   generate-digest     generate-digest
                          │                   │
                   update-pr-map       update-pr-map
                          │                   │
                          └─────────┬─────────┘
                                    ▼
                          ┌─────────────────┐
                          │  Merge to Main  │
                          └────────┬────────┘
                                   │
                            extract-map
                                   │
                            verify-chain
                                   │
                              ┌────▼────┐
                              │ Release │
                              └─────────┘
```

## Usage Example

```yaml
jobs:
  lint:
    steps:
      - uses: arustydev/gha/actions/attestation/generate-digest@v1
        id: digest
        with:
          content: '{"check": "lint", "status": "passed"}'

      - uses: arustydev/gha/actions/attestation/update-pr-map@v1
        with:
          pr-number: ${{ github.event.pull_request.number }}
          check-name: lint
          digest: ${{ steps.digest.outputs.digest }}

  release:
    steps:
      - uses: arustydev/gha/actions/attestation/extract-map@v1
        id: map
        with:
          pr-number: ${{ github.event.pull_request.number }}

      - uses: arustydev/gha/actions/attestation/verify-chain@v1
        with:
          attestation-map: ${{ steps.map.outputs.map }}
```
