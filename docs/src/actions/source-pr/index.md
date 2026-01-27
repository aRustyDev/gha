# Source PR Actions

PR discovery from merge commits.

## Overview

The source-pr actions help trace commits back to their originating pull requests, enabling attestation lineage tracking across multi-stage pipelines.

## Actions

| Action | Description |
|--------|-------------|
| [find](./find.md) | Find source PR from merge commit |

## Use Case

When a PR is merged to `integration` and then atomized into per-artifact PRs, you need to track which source PR each artifact came from:

```
┌──────────────┐     merge      ┌─────────────┐
│  Source PR   │───────────────▶│ integration │
│    #123      │                │   branch    │
└──────────────┘                └──────┬──────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ source-pr/find  │
                              │ → finds #123    │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    ▼                  ▼                  ▼
             ┌────────────┐    ┌────────────┐    ┌────────────┐
             │ Atomic PR  │    │ Atomic PR  │    │ Atomic PR  │
             │ chart-a    │    │ chart-b    │    │ chart-c    │
             │ source:#123│    │ source:#123│    │ source:#123│
             └────────────┘    └────────────┘    └────────────┘
```

## Usage Example

```yaml
jobs:
  atomize:
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # Find the PR that was merged in this push
      - uses: arustydev/gha/actions/source-pr/find@v1
        id: source
        with:
          commit-sha: ${{ github.sha }}
          prefer: merged

      - run: |
          echo "Source PR: #${{ steps.source.outputs.pr-number }}"
          echo "Author: ${{ steps.source.outputs.author }}"
          echo "Title: ${{ steps.source.outputs.title }}"

      # Use source PR info in atomic PR creation
      - uses: arustydev/gha/actions/atomic-branch/create-pr@v1
        with:
          artifact: ${{ matrix.artifact }}
          source-pr: ${{ steps.source.outputs.pr-number }}
```

## Detection Methods

The action uses two methods to find the source PR:

1. **Commit message parsing** - Looks for `#123` patterns in merge commit messages
2. **GitHub API fallback** - Queries `/commits/{sha}/pulls` endpoint

## Outputs

| Output | Description |
|--------|-------------|
| `pr-number` | PR number |
| `found` | Whether a PR was found |
| `author` | PR author username |
| `title` | PR title |
| `labels` | Comma-separated labels |
| `state` | PR state (open/closed/merged) |
| `base-branch` | Target branch |
| `all-prs-json` | JSON array of all associated PRs |
