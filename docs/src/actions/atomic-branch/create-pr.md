# atomic-branch/create-pr

Create PRs with attestation lineage.

## Description

Creates or updates a pull request for an artifact branch, carrying forward attestation maps from source PRs to maintain the chain of trust through the pipeline.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name |
| `branch` | Yes | - | Source branch for PR |
| `target-branch` | No | `main` | Target branch for PR |
| `source-pr` | No | - | Source PR number for lineage |
| `attestation-map` | No | - | JSON attestation map to carry forward |
| `source-branch` | No | - | Original source branch name |
| `commit-sha` | No | - | Source commit SHA |
| `labels` | No | - | Comma-separated labels |
| `reviewers` | No | - | Comma-separated reviewer usernames |
| `team-reviewers` | No | - | Comma-separated team names |
| `draft` | No | `false` | Create as draft PR |
| `token` | No | `github.token` | GitHub token |

## Outputs

| Output | Description |
|--------|-------------|
| `pr-number` | PR number (new or existing) |
| `pr-action` | Action taken: `created`, `updated`, or `failed` |
| `pr-url` | Full PR URL |

## Usage

### Basic PR Creation

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  id: pr
  with:
    artifact: my-chart
    branch: charts/my-chart

- run: echo "PR: ${{ steps.pr.outputs.pr-url }}"
```

### With Attestation Lineage

```yaml
- uses: arustydev/gha/actions/attestation/extract-map@v1
  id: map
  with:
    pr-number: ${{ steps.source.outputs.pr-number }}

- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    artifact: my-chart
    branch: charts/my-chart
    source-pr: ${{ steps.source.outputs.pr-number }}
    attestation-map: ${{ steps.map.outputs.map }}
```

### With Labels and Reviewers

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    artifact: my-chart
    branch: charts/my-chart
    labels: "automated,chart-release"
    reviewers: "maintainer1,maintainer2"
    team-reviewers: "chart-maintainers"
```

### Draft PR

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    artifact: my-chart
    branch: charts/my-chart
    draft: true
```

## PR Body Format

```markdown
## Atomic Release: my-chart

This PR was automatically created for atomic release processing.

### Source
- **PR**: #123
- **Branch**: `feat/add-feature`
- **Commit**: `abc1234`

### Attestation Lineage

<!-- ATTESTATION_MAP_START -->
```json
{
  "lint": "sha256:...",
  "test": "sha256:..."
}
```
<!-- ATTESTATION_MAP_END -->
```

## Idempotent Behavior

- If PR already exists for the branch, updates it instead of creating new
- Handles race conditions gracefully
- Returns existing PR number if found

## Required Permissions

```yaml
permissions:
  contents: write
  pull-requests: write
```
