# trust-check/verify-signatures

Verify commit signatures.

## Description

Verifies that commits in a range are cryptographically signed with GPG or SSH keys. Supports GitHub's web-flow signatures and custom key allowlists.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `commit-range` | No | `HEAD~1..HEAD` | Commit range to verify |
| `require-all` | No | `true` | Require all commits to be signed |
| `allowed-keys` | No | - | Comma-separated GPG key IDs |
| `verify-github` | No | `true` | Accept GitHub web-flow signatures |

## Outputs

| Output | Description |
|--------|-------------|
| `all-signed` | `true` if all commits are signed |
| `signed-count` | Number of signed commits |
| `unsigned-count` | Number of unsigned commits |
| `unsigned-commits` | Comma-separated unsigned commit SHAs |

## Usage

### Basic Verification

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  id: sigs
  with:
    commit-range: origin/main..HEAD

- if: steps.sigs.outputs.all-signed != 'true'
  run: |
    echo "Unsigned commits: ${{ steps.sigs.outputs.unsigned-commits }}"
    exit 1
```

### Verify Single Commit

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  with:
    commit-range: "HEAD~1..HEAD"
```

### With Key Allowlist

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  with:
    commit-range: origin/main..HEAD
    allowed-keys: "4AEE18F83AFDEB23,ABCD1234EFGH5678"
```

### Allow Unsigned (Warning Only)

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  id: sigs
  with:
    commit-range: origin/main..HEAD
    require-all: false

- if: steps.sigs.outputs.unsigned-count > 0
  run: echo "::warning::Found unsigned commits"
```

## Trusted GitHub Keys

GitHub uses these GPG keys for web-flow commits:

| Key ID | Description |
|--------|-------------|
| `4AEE18F83AFDEB23` | GitHub (web-flow) |
| `B5690EEEBB952194` | GitHub (web-flow) |

These are automatically trusted when `verify-github: true`.

## Verification Process

For each commit in range:

1. Run `git verify-commit`
2. Check signature validity
3. If `allowed-keys` specified, verify key ID is in list
4. If `verify-github: true`, accept GitHub's keys
5. Aggregate results

## Signature Types

| Type | Support |
|------|---------|
| GPG | Full support |
| SSH | Full support |
| S/MIME | Not supported |

## Requirements

- GPG must be installed for GPG signatures
- SSH signature verification requires git 2.34+
