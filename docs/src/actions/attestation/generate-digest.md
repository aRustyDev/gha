# attestation/generate-digest

Generate cryptographic digest for attestation subjects.

## Description

Creates a cryptographic hash digest for a file or string content. The output format follows the OCI digest specification (`algorithm:hash`).

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `file-path` | No | - | Path to file to hash |
| `content` | No | - | String content to hash |
| `algorithm` | No | `sha256` | Hash algorithm (`sha256` or `sha512`) |

> **Note:** Either `file-path` or `content` must be provided, but not both.

## Outputs

| Output | Description |
|--------|-------------|
| `digest` | Full digest in `algorithm:hash` format |
| `hash` | Raw hash value (without algorithm prefix) |
| `algorithm` | Algorithm used |

## Usage

### Hash a File

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    file-path: dist/my-package-1.0.0.tar.gz

- run: echo "Digest: ${{ steps.digest.outputs.digest }}"
# Output: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

### Hash String Content

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    content: '{"check": "lint", "status": "passed", "timestamp": "2024-01-15T10:00:00Z"}'

- run: echo "Digest: ${{ steps.digest.outputs.digest }}"
```

### Use SHA-512

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    file-path: dist/my-package.tar.gz
    algorithm: sha512
```

## Digest Format

The output follows the [OCI Content Addressable Storage](https://github.com/opencontainers/image-spec/blob/main/descriptor.md#digests) format:

```
<algorithm>:<hex-encoded-hash>
```

Examples:
- `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- `sha512:cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e`

## Use with Attestation Create

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    file-path: charts/my-chart-1.0.0.tgz

- uses: arustydev/gha/actions/attestation/create@v1
  with:
    subject-name: my-chart-1.0.0.tgz
    subject-digest: ${{ steps.digest.outputs.digest }}
```
