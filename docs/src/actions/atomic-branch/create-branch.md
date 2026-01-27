# atomic-branch/create-branch

Create artifact-specific branches.

## Description

Creates or updates a dedicated branch for a single artifact. Implements retry logic with exponential backoff for push operations and uses `--force-with-lease` for safe updates.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name |
| `artifact-path` | Yes | - | Path to artifacts directory |
| `branch-prefix` | No | `{artifact-path}` | Prefix for branch name |
| `target-branch` | No | `main` | Base branch for new branches |
| `source-sha` | No | `HEAD` | Commit SHA to copy artifact from |
| `source-pr` | No | - | Source PR number for commit message |
| `sign-commits` | No | `false` | Sign commits with GPG |
| `git-user-name` | No | `github-actions[bot]` | Git user name |
| `git-user-email` | No | `github-actions[bot]@users.noreply.github.com` | Git user email |

## Outputs

| Output | Description |
|--------|-------------|
| `branch` | Full branch name created |
| `updated` | `true` if branch was updated |
| `sha` | New branch HEAD SHA |

## Usage

### Basic Branch Creation

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-branch@v1
  id: branch
  with:
    artifact: my-chart
    artifact-path: charts

- run: echo "Created branch: ${{ steps.branch.outputs.branch }}"
# Output: Created branch: charts/my-chart
```

### With Source PR Reference

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-branch@v1
  with:
    artifact: my-chart
    artifact-path: charts
    source-pr: "123"
```

Commit message will include:
```
chore(my-chart): update from source PR #123
```

### Custom Branch Prefix

```yaml
- uses: arustydev/gha/actions/atomic-branch/create-branch@v1
  with:
    artifact: my-chart
    artifact-path: charts
    branch-prefix: release
# Creates branch: release/my-chart
```

## Branch Update Logic

1. Check if branch exists
2. Compare tree hashes to detect actual changes
3. If identical, skip (no-op)
4. If different, create commit and push
5. Use `--force-with-lease` for safe force push
6. Retry with exponential backoff on conflict

## Retry Behavior

- Max retries: 3
- Backoff: 1s, 2s, 4s
- Falls back to force push on final retry

## Required Permissions

```yaml
permissions:
  contents: write
```
