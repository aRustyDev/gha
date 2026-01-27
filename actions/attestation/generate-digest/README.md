# attestation/generate-digest

Generate SHA256/SHA512 digest for attestation subject.

Supports both file content and string content for flexible attestation subjects.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `content` | Yes | - | Content to hash (file path or string) |
| `type` | No | `string` | Content type: `file` or `string` |
| `algorithm` | No | `sha256` | Hash algorithm: `sha256` or `sha512` |

## Outputs

| Output | Description |
|--------|-------------|
| `digest` | Digest in format `algorithm:hash` (e.g., `sha256:abc123...`) |

## Usage

### Hash a String

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    content: '{"workflow": "atomize", "artifacts": ["chart-a", "chart-b"]}'
    type: string

- run: echo "Digest: ${{ steps.digest.outputs.digest }}"
```

### Hash a File

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: file-digest
  with:
    content: charts/my-chart/Chart.yaml
    type: file

- run: echo "File digest: ${{ steps.file-digest.outputs.digest }}"
```

### Use SHA512

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    content: charts/my-chart/Chart.yaml
    type: file
    algorithm: sha512
```

### Use with Attestation Create

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    content: '{"chart": "my-chart", "version": "1.2.3"}'
    type: string

- uses: arustydev/gha/actions/attestation/create@v1
  with:
    subject-name: my-chart-v1.2.3
    subject-digest: ${{ steps.digest.outputs.digest }}
```

## Behavior

- Validates file exists when `type=file`
- Output format is always `algorithm:hash`
- Fails with error if file not found or invalid algorithm
