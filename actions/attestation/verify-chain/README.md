# attestation/verify-chain

Verify all attestations in a chain.

Iterates through an attestation map and verifies each attestation is valid
and was created by the expected repository.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `attestation-map` | Yes | - | JSON object of check_name to attestation_id |
| `repository` | No | `github.repository` | Repository in owner/repo format |
| `fail-fast` | No | `false` | Stop on first failure |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `verified` | `true` if all attestations valid |
| `total` | Total number of attestations checked |
| `passed` | Number that passed verification |
| `failed` | Number that failed verification |
| `results-json` | Detailed JSON results for each attestation |

## Usage

### Basic Verification

```yaml
- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: extract
  with:
    pr-number: ${{ github.event.pull_request.number }}

- uses: arustydev/gha/actions/attestation/verify-chain@v1
  id: verify
  with:
    attestation-map: ${{ steps.extract.outputs.map }}

- run: |
    if [[ "${{ steps.verify.outputs.verified }}" != "true" ]]; then
      echo "Attestation chain verification failed!"
      exit 1
    fi
```

### With Fail-Fast

```yaml
- uses: arustydev/gha/actions/attestation/verify-chain@v1
  id: verify
  with:
    attestation-map: ${{ steps.extract.outputs.map }}
    fail-fast: true
```

### Custom Repository

```yaml
- uses: arustydev/gha/actions/attestation/verify-chain@v1
  id: verify
  with:
    attestation-map: ${{ steps.extract.outputs.map }}
    repository: arustydev/helm-charts
```

### Process Detailed Results

```yaml
- uses: arustydev/gha/actions/attestation/verify-chain@v1
  id: verify
  with:
    attestation-map: ${{ steps.extract.outputs.map }}

- name: Show results
  run: |
    echo "Total: ${{ steps.verify.outputs.total }}"
    echo "Passed: ${{ steps.verify.outputs.passed }}"
    echo "Failed: ${{ steps.verify.outputs.failed }}"
    echo "Details: ${{ steps.verify.outputs.results-json }}"
```

## Results JSON Format

The `results-json` output contains an array of verification results:

```json
[
  {
    "check_name": "lint-test-v1.32.11",
    "attestation_id": "abc123",
    "status": "passed",
    "method": "oci"
  },
  {
    "check_name": "install-test-v1.32.11",
    "attestation_id": "def456",
    "status": "passed",
    "method": "api"
  }
]
```

## Verification Methods

1. **OCI Bundle** (preferred): Verifies using `gh attestation verify --bundle-from-oci`
2. **API** (fallback): Verifies using GitHub REST API

## Behavior

- Tries OCI bundle verification first, falls back to API
- Reports detailed results for each attestation
- With `fail-fast: true`, stops on first verification failure
- With `fail-fast: false` (default), continues and reports all failures
