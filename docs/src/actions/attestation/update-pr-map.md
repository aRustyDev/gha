# attestation/update-pr-map

Update PR description with attestation entry.

## Description

Adds or removes an attestation entry in a PR's description. The attestation map is stored in HTML comment markers to preserve it across PR description edits.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `pr-number` | Yes | - | PR number to update |
| `check-name` | Yes | - | Name of the check/stage |
| `digest` | Yes | - | Attestation digest |
| `action` | No | `add` | Action to perform (`add` or `remove`) |
| `token` | No | `github.token` | GitHub token with PR write access |

## Outputs

| Output | Description |
|--------|-------------|
| `updated` | `true` if PR was updated |
| `map` | Updated attestation map JSON |

## Usage

### Add Attestation Entry

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    content: '{"check": "lint", "passed": true}'

- uses: arustydev/gha/actions/attestation/update-pr-map@v1
  with:
    pr-number: ${{ github.event.pull_request.number }}
    check-name: lint
    digest: ${{ steps.digest.outputs.digest }}
```

### Remove Attestation Entry

```yaml
- uses: arustydev/gha/actions/attestation/update-pr-map@v1
  with:
    pr-number: ${{ github.event.pull_request.number }}
    check-name: old-check
    digest: ""
    action: remove
```

## Concurrency Handling

The action implements exponential backoff retry logic to handle concurrent updates:

1. Fetch current PR body
2. Parse existing attestation map
3. Update map with new entry
4. Attempt to update PR description
5. If conflict detected, retry with fresh data

Default: 3 retries with exponential backoff (1s, 2s, 4s)

## PR Body Format

Before:
```markdown
## Description
This PR adds a new feature.

## Changes
- Added feature X
```

After:
```markdown
## Description
This PR adds a new feature.

## Changes
- Added feature X

<!-- ATTESTATION_MAP_START -->
```json
{
  "lint": "sha256:abc123...",
  "test": "sha256:def456..."
}
```
<!-- ATTESTATION_MAP_END -->
```

## Required Permissions

```yaml
permissions:
  pull-requests: write
```
