# atomic-branch/create-branch

Create or update an artifact-specific branch for atomic release processing.

For each changed artifact, this action creates a dedicated branch (e.g., `charts/my-chart`) containing only changes for that artifact. This enables per-artifact PRs and release tracking.

## Usage

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-branch@v1
  id: branch
  with:
    artifact: my-chart
    artifact-path: charts
    branch-prefix: charts
    target-branch: main

- run: echo "Branch: ${{ steps.branch.outputs.branch }}"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name |
| `artifact-path` | Yes | - | Path to artifacts directory |
| `branch-prefix` | No | `<artifact-path>` | Prefix for branch name |
| `target-branch` | No | `main` | Base branch for new branches |
| `source-sha` | No | `github.sha` | Commit SHA to copy artifact from |
| `source-pr` | No | - | Source PR number (for commit message) |
| `sign-commits` | No | `false` | Sign commits with GPG |
| `git-user-name` | No | `github-actions[bot]` | Git user name for commits |
| `git-user-email` | No | `github-actions[bot]@users.noreply.github.com` | Git user email |

## Outputs

| Output | Description |
|--------|-------------|
| `branch` | Full branch name (e.g., "charts/my-chart") |
| `updated` | "true" if branch was updated, "false" if no changes |
| `sha` | New branch HEAD SHA |

## Examples

### Basic usage

```yaml
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0
      token: ${{ secrets.GITHUB_TOKEN }}

  - uses: arustydev/gha/actions/atomic-branch/create-branch@v1
    id: branch
    with:
      artifact: my-chart
      artifact-path: charts

  - if: steps.branch.outputs.updated == 'true'
    run: echo "Branch ${{ steps.branch.outputs.branch }} was updated"
```

### With source PR tracking

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-branch@v1
  id: branch
  with:
    artifact: my-chart
    artifact-path: charts
    target-branch: main
    source-pr: ${{ github.event.pull_request.number }}
```

### Matrix strategy for multiple artifacts

```yaml
jobs:
  detect:
    runs-on: ubuntu-latest
    outputs:
      artifacts: ${{ steps.detect.outputs.artifacts-json }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: arustydev/gha/actions/atomic-branch/detect-changes@v1
        id: detect
        with:
          artifact-path: charts
          manifest-file: Chart.yaml

  create-branches:
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
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: arustydev/gha/actions/atomic-branch/create-branch@v1
        id: branch
        with:
          artifact: ${{ matrix.artifact }}
          artifact-path: charts
          branch-prefix: charts
```

### With signed commits

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-branch@v1
  with:
    artifact: my-chart
    artifact-path: charts
    sign-commits: true
    git-user-name: "Release Bot"
    git-user-email: "release-bot@example.com"
```

## Prerequisites

- Repository must be checked out with full history (`fetch-depth: 0`)
- Token must have write access to create/push branches
- Target branch must exist in the repository

## How it works

1. Determines the branch name from prefix and artifact name
2. Checks if the branch already exists remotely
3. If exists, compares tree hashes to detect actual changes
4. Creates or updates the branch from the target branch
5. Copies the artifact directory from the source commit
6. Commits changes with optional source PR reference
7. Pushes with retry logic and force-with-lease for safety

## Retry Logic

The action implements exponential backoff retry for push operations:

1. First attempt: immediate push with `--force-with-lease`
2. On failure: fetch, rebase, wait 2s, retry
3. On second failure: fetch, rebase, wait 4s, retry
4. Final fallback: force push without lease

This handles concurrent updates gracefully while preferring safe push operations.

## Branch Naming

The branch name is constructed as:

```
<branch-prefix>/<artifact>
```

If `branch-prefix` is not provided, `artifact-path` is used:

```
<artifact-path>/<artifact>
```

Examples:
- `charts/my-chart`
- `crates/my-crate`
- `packages/my-package`
