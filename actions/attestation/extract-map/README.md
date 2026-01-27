# attestation/extract-map

Extract attestation map from PR description.

The attestation map is stored in PR descriptions using HTML comments:

```html
<!-- ATTESTATION_MAP
{"lint-test-v1.32.11": "attestation-id-1", "install-test-v1.32.11": "attestation-id-2"}
-->
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `pr-number` | Yes | - | PR number to extract from |
| `body` | No | - | Alternative: PR body content (if already fetched) |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `map` | JSON object of check_name to attestation_id |
| `count` | Number of entries in the map |
| `empty` | `true` if map is empty, `false` otherwise |

## Usage

### Basic Usage

```yaml
- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: attestation
  with:
    pr-number: ${{ github.event.pull_request.number }}

- run: echo "Found ${{ steps.attestation.outputs.count }} attestations"
```

### With Pre-fetched Body

```yaml
- name: Get PR body
  id: pr
  run: echo "body=$(gh pr view ${{ github.event.pull_request.number }} --json body -q '.body')" >> "$GITHUB_OUTPUT"

- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: attestation
  with:
    pr-number: ${{ github.event.pull_request.number }}
    body: ${{ steps.pr.outputs.body }}
```

### Check If Empty

```yaml
- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: attestation
  with:
    pr-number: ${{ github.event.pull_request.number }}

- name: Verify attestations exist
  if: steps.attestation.outputs.empty == 'true'
  run: |
    echo "::error::No attestations found in PR"
    exit 1
```

## Behavior

- Returns empty JSON object `{}` if no map found
- Returns empty JSON object `{}` if map contains invalid JSON
- Handles missing or malformed attestation maps gracefully
- Validates JSON before returning
