# attestation/update-pr-map

Update attestation map in PR description.

Adds or updates an attestation ID for a given check name in the PR description,
using HTML comments:

```html
<!-- ATTESTATION_MAP
{"lint-test-v1.32.11": "attestation-id-1", "install-test-v1.32.11": "attestation-id-2"}
-->
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `pr-number` | Yes | - | PR number to update |
| `check-name` | Yes | - | Name of the check (e.g., `lint-test-v1.32.11`) |
| `attestation-id` | Yes | - | The attestation ID to store |
| `action` | No | `add` | Action to perform: `add` or `remove` |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `updated` | `true` if successfully updated |
| `map` | Updated JSON object |

## Usage

### Add Attestation

```yaml
- uses: arustydev/gha/actions/attestation/update-pr-map@v1
  with:
    pr-number: ${{ github.event.pull_request.number }}
    check-name: "lint-test-v1.32.11"
    attestation-id: ${{ steps.attest.outputs.attestation-id }}
```

### Remove Attestation

```yaml
- uses: arustydev/gha/actions/attestation/update-pr-map@v1
  with:
    pr-number: ${{ github.event.pull_request.number }}
    check-name: "lint-test-v1.32.11"
    attestation-id: ""
    action: remove
```

### With Custom Token

```yaml
- uses: arustydev/gha/actions/attestation/update-pr-map@v1
  with:
    pr-number: ${{ github.event.pull_request.number }}
    check-name: "install-test-v1.32.11"
    attestation-id: ${{ steps.attest.outputs.attestation-id }}
    token: ${{ secrets.GITHUB_TOKEN }}
```

### Check Update Status

```yaml
- uses: arustydev/gha/actions/attestation/update-pr-map@v1
  id: update
  with:
    pr-number: ${{ github.event.pull_request.number }}
    check-name: "lint-test"
    attestation-id: ${{ steps.attest.outputs.attestation-id }}

- name: Verify update
  if: steps.update.outputs.updated != 'true'
  run: |
    echo "::error::Failed to update attestation map"
    exit 1
```

## Behavior

- Uses exponential backoff retry for concurrent updates (5 retries max)
- Creates map section if it doesn't exist
- Preserves existing attestations when adding new ones
- Handles race conditions with concurrent PR updates
