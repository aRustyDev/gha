# source-pr/find

Find the source PR from a merge commit.

This action extracts the PR number from merge commit messages or queries the GitHub API as a fallback. Useful for workflows that need to trace commits back to their originating PRs.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `commit-sha` | No | `github.sha` | Commit SHA to check |
| `prefer` | No | `merged` | Preference when multiple PRs found: `first`, `merged`, or `open` |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `pr-number` | PR number if found, empty otherwise |
| `found` | `true` if PR was found |
| `author` | PR author login |
| `labels` | Comma-separated list of PR labels |
| `state` | PR state: `open`, `closed`, or `merged` |
| `title` | PR title |
| `base-branch` | Base branch the PR targets |
| `all-prs-json` | JSON array of all associated PRs |

## Usage Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source
  with:
    commit-sha: ${{ github.sha }}

- run: |
    if [[ "${{ steps.source.outputs.found }}" == "true" ]]; then
      echo "Source PR: #${{ steps.source.outputs.pr-number }}"
      echo "Author: ${{ steps.source.outputs.author }}"
    fi
```

### With Preference Selection

```yaml
# Prefer merged PRs when multiple exist
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source
  with:
    commit-sha: ${{ github.sha }}
    prefer: merged

# Prefer open PRs (useful for draft detection)
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source
  with:
    prefer: open
```

### Using All PRs JSON

```yaml
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source

- name: Process all associated PRs
  run: |
    echo '${{ steps.source.outputs.all-prs-json }}' | jq -r '.[].number'
```

### Conditional on Labels

```yaml
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source

- if: contains(steps.source.outputs.labels, 'skip-ci')
  run: echo "Skipping CI due to label"
```

## How It Works

1. **Parse Commit Message**: Extracts PR number from patterns like `(#123)` or `Merge pull request #123`
2. **GitHub API Fallback**: Queries `/repos/{owner}/{repo}/commits/{sha}/pulls` for associated PRs
3. **PR Validation**: Fetches full PR details including author, labels, and state
4. **Selection**: When multiple PRs exist, selects based on `prefer` input

## Requirements

- Git must be available in the runner
- `gh` CLI must be available (pre-installed on GitHub-hosted runners)
- Token needs `repo` scope for private repositories
