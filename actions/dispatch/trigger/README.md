# dispatch/trigger

Trigger `repository_dispatch` events to invoke other workflows.

This action provides a clean interface for dispatching events with JSON payloads, with proper validation and error handling.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `event-type` | Yes | - | Event type to dispatch |
| `client-payload` | No | `{}` | JSON payload to send with the event |
| `repository` | No | `github.repository` | Target repository (owner/repo format) |
| `token` | No | `github.token` | GitHub token (needs `repo` scope for cross-repo) |

## Outputs

| Output | Description |
|--------|-------------|
| `dispatched` | `true` if successfully dispatched |

## Usage Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: "chart-pr-created"
```

### With Payload

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: "chart-pr-created"
    client-payload: '{"pr": 123, "chart": "my-chart", "version": "1.0.0"}'
```

### Dynamic Payload

```yaml
- name: Build payload
  id: payload
  run: |
    payload=$(jq -n \
      --arg pr "${{ github.event.pull_request.number }}" \
      --arg chart "${{ steps.detect.outputs.chart }}" \
      '{pr: ($pr | tonumber), chart: $chart}')
    echo "json=$payload" >> "$GITHUB_OUTPUT"

- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: "chart-ready"
    client-payload: ${{ steps.payload.outputs.json }}
```

### Cross-Repository Dispatch

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: "deployment-ready"
    repository: "myorg/deployment-controller"
    client-payload: '{"source": "${{ github.repository }}", "ref": "${{ github.sha }}"}'
    token: ${{ secrets.CROSS_REPO_PAT }}
```

### Trigger Validation Workflow

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: "validate-chart"
    client-payload: |
      {
        "pr_number": ${{ github.event.pull_request.number }},
        "head_sha": "${{ github.event.pull_request.head.sha }}",
        "chart": "${{ steps.detect.outputs.chart }}"
      }
```

## Receiving Dispatched Events

Create a workflow that listens for your event:

```yaml
name: Handle Chart PR Created

on:
  repository_dispatch:
    types: [chart-pr-created]

jobs:
  handle:
    runs-on: ubuntu-latest
    steps:
      - name: Access payload
        run: |
          echo "PR: ${{ github.event.client_payload.pr }}"
          echo "Chart: ${{ github.event.client_payload.chart }}"
```

## Token Requirements

| Scenario | Token Scope Required |
|----------|---------------------|
| Same repository | `GITHUB_TOKEN` (default) |
| Cross-repository (same org) | PAT with `repo` scope |
| Cross-repository (different org) | PAT with `repo` scope |

Note: `GITHUB_TOKEN` cannot trigger workflows in other repositories.

## Error Handling

The action validates the JSON payload before dispatching. If the payload is invalid JSON, the action fails with a clear error message.

```yaml
- uses: arustydev/gha/actions/dispatch/trigger@v1
  id: dispatch
  continue-on-error: true
  with:
    event-type: "my-event"
    client-payload: '{"key": "value"}'

- if: steps.dispatch.outputs.dispatched != 'true'
  run: echo "::error::Failed to dispatch event"
```

## Common Patterns

### Chain Workflows

```yaml
# Workflow A: Detect and dispatch
- uses: arustydev/gha/actions/dispatch/trigger@v1
  with:
    event-type: "step-1-complete"
    client-payload: '{"result": "success", "data": "${{ steps.process.outputs.data }}"}'

# Workflow B: Receives and continues
on:
  repository_dispatch:
    types: [step-1-complete]
```

### Fan-Out Pattern

```yaml
- name: Dispatch to multiple targets
  run: |
    charts="${{ steps.detect.outputs.charts }}"
    for chart in $charts; do
      echo "Dispatching for $chart"
    done
  # Then use matrix or loop with this action
```
