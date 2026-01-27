# attestation/verify-chain

Verify complete attestation chain.

## Description

Verifies all attestations in an attestation map, ensuring the complete chain of trust is valid. Uses GitHub's attestation verification API with OCI bundle fallback.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `attestation-map` | Yes | - | JSON attestation map to verify |
| `fail-fast` | No | `true` | Stop on first failure |
| `owner` | No | Repository owner | Owner for attestation lookup |
| `allowed-repos` | No | - | Comma-separated allowed source repos |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `verified` | `true` if all attestations verified |
| `verified-count` | Number of verified attestations |
| `failed-count` | Number of failed verifications |
| `results-json` | Detailed results per attestation |

## Usage

### Basic Verification

```yaml
- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: map
  with:
    pr-number: ${{ github.event.pull_request.number }}

- uses: arustydev/gha/actions/attestation/verify-chain@v1
  id: verify
  with:
    attestation-map: ${{ steps.map.outputs.map }}

- if: steps.verify.outputs.verified != 'true'
  run: |
    echo "Attestation verification failed!"
    echo "${{ steps.verify.outputs.results-json }}" | jq .
    exit 1
```

### Continue on Failure

```yaml
- uses: arustydev/gha/actions/attestation/verify-chain@v1
  id: verify
  with:
    attestation-map: ${{ steps.map.outputs.map }}
    fail-fast: false

- run: |
    echo "Verified: ${{ steps.verify.outputs.verified-count }}"
    echo "Failed: ${{ steps.verify.outputs.failed-count }}"
```

### Cross-Repository Verification

```yaml
- uses: arustydev/gha/actions/attestation/verify-chain@v1
  with:
    attestation-map: ${{ steps.map.outputs.map }}
    allowed-repos: "myorg/source-repo,myorg/other-repo"
```

## Verification Process

1. Parse attestation map JSON
2. For each entry:
   - Query GitHub Attestations API
   - Verify signature and certificate chain
   - Check predicate type matches expected
   - Validate subject digest
3. Aggregate results

## Results Format

```json
[
  {
    "check": "lint",
    "digest": "sha256:abc123...",
    "status": "verified",
    "attestation_id": "att_123..."
  },
  {
    "check": "test",
    "digest": "sha256:def456...",
    "status": "failed",
    "error": "Attestation not found"
  }
]
```

## Required Permissions

```yaml
permissions:
  attestations: read
  id-token: write  # For OIDC verification
```
