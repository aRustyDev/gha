# attestation/create

Create attestation with optional PR map update.

Wraps `actions/attest-build-provenance` with a consistent interface and
automatically updates the PR attestation map if `pr-number` and `check-name`
are provided.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `subject-name` | Yes | - | Name for the attestation subject |
| `subject-digest` | Yes | - | SHA256 digest of the subject |
| `pr-number` | No | - | PR number to update attestation map |
| `check-name` | No | - | Check name for attestation map entry |
| `push-to-registry` | No | `false` | Push attestation to GHCR |
| `token` | No | `github.token` | GitHub token |

## Outputs

| Output | Description |
|--------|-------------|
| `attestation-id` | The generated attestation ID |
| `bundle-path` | Path to the attestation bundle |

## Usage

### Basic Attestation

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    content: '{"chart": "my-chart", "version": "1.2.3"}'
    type: string

- uses: arustydev/gha/actions/attestation/create@v1
  id: attest
  with:
    subject-name: my-chart-v1.2.3
    subject-digest: ${{ steps.digest.outputs.digest }}
```

### With PR Map Update

```yaml
- uses: arustydev/gha/actions/attestation/create@v1
  id: attest
  with:
    subject-name: my-chart-v1.2.3
    subject-digest: ${{ steps.digest.outputs.digest }}
    pr-number: ${{ github.event.pull_request.number }}
    check-name: lint-test
```

### Push to Registry

```yaml
- uses: arustydev/gha/actions/attestation/create@v1
  id: attest
  with:
    subject-name: my-chart-v1.2.3
    subject-digest: ${{ steps.digest.outputs.digest }}
    push-to-registry: true
```

### Full Example (Lint Test)

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run lint
        run: helm lint charts/my-chart

      - uses: arustydev/gha/actions/attestation/generate-digest@v1
        id: digest
        with:
          content: '{"check": "lint", "chart": "my-chart", "version": "${{ env.VERSION }}"}'

      - uses: arustydev/gha/actions/attestation/create@v1
        id: attest
        with:
          subject-name: lint-my-chart-${{ env.VERSION }}
          subject-digest: ${{ steps.digest.outputs.digest }}
          pr-number: ${{ github.event.pull_request.number }}
          check-name: lint-test-${{ env.VERSION }}
```

## Behavior

- Wraps `actions/attest-build-provenance@v2`
- Optionally updates PR attestation map if both `pr-number` and `check-name` are provided
- Logs detailed attestation information for debugging
- Provides consistent interface with other attestation actions
