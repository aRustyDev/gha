# Dispatch Actions

Workflow event triggering for pipeline orchestration.

## Overview

The dispatch actions enable workflows to trigger other workflows via `repository_dispatch` events, useful for:
- Cross-repository automation
- Pipeline stage transitions
- Event-driven architectures

## Actions

| Action | Description |
|--------|-------------|
| [trigger](./trigger.md) | Trigger repository_dispatch event |

## Use Case

Trigger downstream workflows when a release is published:

```
┌─────────────────┐          ┌─────────────────┐
│  Release        │          │  Docs Repo      │
│  Workflow       │          │  Workflow       │
│                 │          │                 │
│  1. Build       │          │                 │
│  2. Test        │          │                 │
│  3. Publish     │          │                 │
│  4. dispatch ───┼──────────▶  on: dispatch   │
│     trigger     │          │  → Update docs  │
└─────────────────┘          └─────────────────┘
```

## Usage Example

### Triggering Workflow

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    steps:
      - name: Build and publish
        run: make release

      # Trigger docs update in another repo
      - uses: arustydev/gha/actions/dispatch/trigger@v1
        with:
          event-type: release-published
          repository: myorg/docs
          client-payload: |
            {
              "version": "${{ github.ref_name }}",
              "repository": "${{ github.repository }}",
              "sha": "${{ github.sha }}"
            }
        env:
          GITHUB_TOKEN: ${{ secrets.DISPATCH_TOKEN }}
```

### Receiving Workflow

```yaml
name: Update Docs

on:
  repository_dispatch:
    types: [release-published]

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Updating docs for ${{ github.event.client_payload.repository }}"
          echo "Version: ${{ github.event.client_payload.version }}"
```

## Event Types

Use descriptive event types that indicate the action:

| Event Type | Description |
|------------|-------------|
| `release-published` | New release was published |
| `chart-updated` | Helm chart was updated |
| `deploy-staging` | Request staging deployment |
| `run-integration-tests` | Trigger integration test suite |

## Payload Schema

The `client-payload` must be valid JSON:

```json
{
  "version": "1.2.3",
  "artifact": "my-chart",
  "source_repo": "org/source-repo",
  "source_sha": "abc123",
  "triggered_by": "release-workflow"
}
```

## Cross-Repository Dispatch

To dispatch to another repository, use a PAT or GitHub App token with `repo` scope:

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    repository: other-org/other-repo
    event-type: my-event
  env:
    GITHUB_TOKEN: ${{ secrets.CROSS_REPO_TOKEN }}
```
