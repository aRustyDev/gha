# attestation/create

Create attestation (wrapper for attest-build-provenance).

## Description

Creates a SLSA provenance attestation for a build artifact. This is a convenience wrapper around `actions/attest-build-provenance` that optionally updates the PR attestation map.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `subject-name` | Yes | - | Name of the artifact |
| `subject-digest` | Yes | - | Digest of the artifact |
| `push-to-registry` | No | `false` | Push attestation to OCI registry |
| `pr-number` | No | - | PR number to update attestation map |
| `check-name` | No | - | Check name for attestation map |
| `token` | No | `github.token` | GitHub token |

## Outputs

| Output | Description |
|--------|-------------|
| `attestation-id` | ID of created attestation |
| `bundle-path` | Path to attestation bundle file |

## Usage

### Basic Attestation

```yaml
- uses: arustydev/gha/actions/attestation/generate-digest@v1
  id: digest
  with:
    file-path: dist/my-package.tar.gz

- uses: arustydev/gha/actions/attestation/create@v1
  id: attest
  with:
    subject-name: my-package.tar.gz
    subject-digest: ${{ steps.digest.outputs.digest }}
```

### With PR Map Update

```yaml
- uses: arustydev/gha/actions/attestation/create@v1
  with:
    subject-name: lint-${{ matrix.chart }}
    subject-digest: ${{ steps.digest.outputs.digest }}
    pr-number: ${{ github.event.pull_request.number }}
    check-name: lint-${{ matrix.chart }}
```

### Push to Registry

```yaml
- uses: arustydev/gha/actions/attestation/create@v1
  with:
    subject-name: ghcr.io/myorg/myimage:v1.0.0
    subject-digest: ${{ steps.build.outputs.digest }}
    push-to-registry: true
```

## SLSA Provenance

The created attestation includes SLSA v1.0 provenance:

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [{
    "name": "my-package.tar.gz",
    "digest": {"sha256": "abc123..."}
  }],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "https://actions.github.io/buildtypes/workflow/v1",
      "externalParameters": {
        "workflow": {
          "ref": "refs/heads/main",
          "repository": "https://github.com/myorg/myrepo"
        }
      }
    },
    "runDetails": {
      "builder": {
        "id": "https://github.com/actions/runner"
      }
    }
  }
}
```

## Required Permissions

```yaml
permissions:
  attestations: write
  id-token: write
  contents: read
```
