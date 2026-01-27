# dispatch/trigger

Trigger repository_dispatch event.

## Description

Triggers a `repository_dispatch` event to invoke workflows in the same or another repository. Useful for pipeline orchestration and cross-repository automation.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `event-type` | Yes | - | Event type identifier |
| `client-payload` | No | `{}` | JSON payload for the event |
| `repository` | No | Current repo | Target repository (owner/repo) |
| `token` | No | `github.token` | GitHub token with repo scope |

## Outputs

| Output | Description |
|--------|-------------|
| `dispatched` | `true` if event was sent |

## Usage

### Basic Dispatch

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: deploy-staging
```

### With Payload

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: release-published
    client-payload: |
      {
        "version": "${{ github.ref_name }}",
        "sha": "${{ github.sha }}",
        "artifact": "my-chart"
      }
```

### Cross-Repository Dispatch

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: update-docs
    repository: myorg/docs
    client-payload: |
      {
        "source_repo": "${{ github.repository }}",
        "version": "${{ steps.version.outputs.next }}"
      }
  env:
    GITHUB_TOKEN: ${{ secrets.CROSS_REPO_TOKEN }}
```

## Receiving Workflow

```yaml
name: Handle Dispatch

on:
  repository_dispatch:
    types: [deploy-staging, release-published]

jobs:
  handle:
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Event: ${{ github.event.action }}"
          echo "Payload: ${{ toJson(github.event.client_payload) }}"
```

## Event Types

Use descriptive, action-oriented event types:

| Event Type | Use Case |
|------------|----------|
| `deploy-staging` | Trigger staging deployment |
| `deploy-production` | Trigger production deployment |
| `release-published` | Notify of new release |
| `chart-updated` | Helm chart was updated |
| `run-e2e-tests` | Trigger E2E test suite |
| `sync-docs` | Synchronize documentation |

## Payload Schema

Design payloads with all necessary context:

```json
{
  "version": "1.2.3",
  "artifact": "my-chart",
  "source": {
    "repo": "org/source-repo",
    "sha": "abc1234",
    "ref": "refs/tags/v1.2.3"
  },
  "metadata": {
    "triggered_by": "release-workflow",
    "timestamp": "2024-01-15T10:00:00Z"
  }
}
```

## Token Requirements

| Scope | Use Case |
|-------|----------|
| Default `GITHUB_TOKEN` | Same repository |
| PAT with `repo` scope | Cross-repository |
| GitHub App token | Cross-repository (recommended) |

## Error Handling

- Validates JSON payload before sending
- Returns error if repository not found
- Returns error if token lacks permissions
