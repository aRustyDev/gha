# attestation/extract-map

Extract attestation map from PR description.

## Description

Parses a PR description to extract the attestation map JSON stored in HTML comment markers. This enables downstream workflows to access attestation data from previous pipeline stages.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `pr-number` | No | - | PR number to extract from |
| `body` | No | - | PR body to extract from (alternative to pr-number) |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `map` | JSON attestation map |
| `count` | Number of entries in map |
| `empty` | `true` if map is empty or not found |

## Usage

### Extract from PR Number

```yaml
- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: attestations
  with:
    pr-number: ${{ github.event.pull_request.number }}

- run: |
    echo "Found ${{ steps.attestations.outputs.count }} attestations"
    echo "Map: ${{ steps.attestations.outputs.map }}"
```

### Extract from Pre-fetched Body

```yaml
- id: pr
  run: |
    body=$(gh pr view ${{ env.PR_NUMBER }} --json body -q .body)
    echo "body<<EOF" >> $GITHUB_OUTPUT
    echo "$body" >> $GITHUB_OUTPUT
    echo "EOF" >> $GITHUB_OUTPUT

- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: attestations
  with:
    body: ${{ steps.pr.outputs.body }}
```

## Map Format

The action looks for this pattern in the PR body:

```html
<!-- ATTESTATION_MAP_START -->
```json
{
  "check-name-1": "sha256:abc123...",
  "check-name-2": "sha256:def456..."
}
```
<!-- ATTESTATION_MAP_END -->
```

## Error Handling

- Returns empty map `{}` if markers not found
- Validates JSON structure before returning
- Sets `empty: true` if no valid map found
