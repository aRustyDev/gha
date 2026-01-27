# atomic-branch/create-pr

Create or update a PR with attestation lineage for atomic release processing.

For each artifact branch, this action creates a PR to the target branch that carries forward the attestation chain from the source PR. This enables cryptographic verification of the complete release pipeline.

## Usage

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  id: pr
  with:
    artifact: my-chart
    branch: charts/my-chart
    target-branch: main
    source-pr: 123
    attestation-map: '{"lint": "att-123", "test": "att-456"}'

- run: echo "PR: ${{ steps.pr.outputs.pr-url }}"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name |
| `branch` | Yes | - | Source branch for PR |
| `target-branch` | No | `main` | Target branch for PR |
| `source-pr` | No | - | Source PR number (for lineage) |
| `attestation-map` | No | `{}` | JSON attestation map to carry forward |
| `source-branch` | No | `integration` | Original source branch name |
| `commit-sha` | No | `github.sha` | Source commit SHA for reference |
| `labels` | No | - | Comma-separated list of labels |
| `reviewers` | No | - | Comma-separated list of reviewers |
| `team-reviewers` | No | - | Comma-separated list of team reviewers |
| `draft` | No | `false` | Create PR as draft |
| `token` | No | `github.token` | GitHub token for API operations |

## Outputs

| Output | Description |
|--------|-------------|
| `pr-number` | PR number (new or existing) |
| `pr-action` | Action taken: `created`, `updated`, or `failed` |
| `pr-url` | Full PR URL |

## Examples

### Basic usage

```yaml
steps:
  - uses: arustydev/gha/actions/atomic-branch/create-pr@v1
    id: pr
    with:
      artifact: my-chart
      branch: charts/my-chart

  - if: steps.pr.outputs.pr-action == 'created'
    run: echo "Created new PR: ${{ steps.pr.outputs.pr-url }}"
```

### With attestation lineage

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    artifact: my-chart
    branch: charts/my-chart
    target-branch: main
    source-pr: ${{ needs.detect.outputs.source-pr }}
    attestation-map: ${{ needs.detect.outputs.attestation-map }}
    source-branch: integration
    commit-sha: ${{ github.sha }}
```

### With labels and reviewers

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    artifact: my-chart
    branch: charts/my-chart
    labels: "scope:chart, automation, release"
    reviewers: "maintainer1, maintainer2"
    team-reviewers: "my-org/release-team"
```

### Full atomic release pipeline

```yaml
jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      artifacts: ${{ steps.detect.outputs.artifacts-json }}
      source-pr: ${{ steps.source.outputs.pr-number }}
      attestation-map: ${{ steps.source.outputs.attestation-map }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
        id: detect
        with:
          artifact-path: charts
          manifest-file: Chart.yaml
      # ... find source PR and extract attestation map

  create-prs:
    needs: detect
    runs-on: ubuntu-latest
    strategy:
      matrix:
        artifact: ${{ fromJson(needs.detect.outputs.artifacts) }}
      fail-fast: false
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: arustydev/gha/actions/atomic-branch/create-branch@v1
        id: branch
        with:
          artifact: ${{ matrix.artifact }}
          artifact-path: charts

      - uses: arustydev/gha/actions/atomic-branch/create-pr@v1
        id: pr
        with:
          artifact: ${{ matrix.artifact }}
          branch: ${{ steps.branch.outputs.branch }}
          target-branch: main
          source-pr: ${{ needs.detect.outputs.source-pr }}
          attestation-map: ${{ needs.detect.outputs.attestation-map }}
```

## Attestation Map Format

The attestation map is a JSON object that maps check names to attestation IDs:

```json
{
  "lint-test-v1.32.11": "sha256:abc123...",
  "install-test-v1.32.11": "sha256:def456...",
  "security-scan": "sha256:789ghi..."
}
```

This map is embedded in the PR body using HTML comments:

```markdown
<!-- ATTESTATION_MAP
{"lint-test-v1.32.11": "sha256:abc123..."}
-->
```

Downstream workflows can extract and verify these attestations to ensure the complete pipeline integrity.

## PR Body Template

The generated PR body includes:

1. **Artifact name** - The artifact being promoted
2. **Source information** - Source PR, branch, and commit SHA
3. **Attestation lineage** - Expandable section showing attestation entries
4. **Hidden attestation map** - Machine-readable attestation data in HTML comment

## Race Condition Handling

The action handles race conditions gracefully:

1. First checks for existing PR before creating
2. If PR creation fails due to existing PR (race), updates the existing one
3. Returns appropriate `pr-action` output (`updated` vs `created`)

## Token Permissions

The token needs the following permissions:

- `pull-requests: write` - To create/update PRs
- `contents: read` - To read branch information

For elevated operations (bypassing branch protection), use a GitHub App token:

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-pr@v1
  with:
    token: ${{ secrets.APP_TOKEN }}
    # ... other inputs
```
