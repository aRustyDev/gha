# source-pr/find

Find source PR from merge commit.

## Description

Finds the pull request that introduced a commit by parsing the commit message or querying the GitHub API. Essential for tracking attestation lineage through multi-stage pipelines.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `commit-sha` | No | `github.sha` | Commit SHA to look up |
| `prefer` | No | `merged` | Preference when multiple PRs: `first`, `merged`, `open` |
| `token` | No | `github.token` | GitHub token for API access |

## Outputs

| Output | Description |
|--------|-------------|
| `pr-number` | PR number |
| `found` | `true` if PR was found |
| `author` | PR author username |
| `title` | PR title |
| `labels` | Comma-separated labels |
| `state` | PR state: `open`, `closed`, `merged` |
| `base-branch` | Target branch of PR |
| `all-prs-json` | JSON array of all associated PRs |

## Usage

### Basic Usage

```yaml
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source
  with:
    commit-sha: ${{ github.sha }}

- run: |
    echo "Source PR: #${{ steps.source.outputs.pr-number }}"
    echo "Author: ${{ steps.source.outputs.author }}"
```

### In Push Workflow

```yaml
on:
  push:
    branches: [main]

jobs:
  find-source:
    steps:
      - uses: arustydev/gha/actions/source-pr/find@v1
        id: source

      - if: steps.source.outputs.found == 'true'
        run: echo "Merged from PR #${{ steps.source.outputs.pr-number }}"
```

### Prefer Open PR

```yaml
- uses: arustydev/gha/actions/source-pr/find@v1
  with:
    prefer: open
```

### Use All PRs

```yaml
- uses: arustydev/gha/actions/source-pr/find@v1
  id: source

- run: |
    echo '${{ steps.source.outputs.all-prs-json }}' | jq '.[] | .number'
```

## Detection Methods

### 1. Commit Message Parsing

Looks for PR references in commit message:

```
Merge pull request #123 from user/branch
```

```
feat: add feature (#456)
```

### 2. GitHub API Fallback

Queries `/repos/{owner}/{repo}/commits/{sha}/pulls` endpoint.

## Preference Options

| Option | Description |
|--------|-------------|
| `first` | Return first PR found |
| `merged` | Prefer merged PRs |
| `open` | Prefer open PRs |

## All PRs JSON Format

```json
[
  {
    "number": 123,
    "title": "Add feature",
    "state": "merged",
    "author": "user",
    "labels": ["enhancement"],
    "base": "main"
  }
]
```

## Use Cases

1. **Attestation lineage** - Find source PR to carry forward attestations
2. **Release notes** - Link releases to originating PRs
3. **Automation triggers** - Identify which PR caused a workflow run
