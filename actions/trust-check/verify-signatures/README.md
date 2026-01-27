# trust-check/verify-signatures

Verify GPG/SSH commit signatures in a commit range.

This action checks that commits in a specified range are properly signed, with support for GitHub's web-flow signatures and allowlists of specific GPG keys.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `commit-range` | No | `HEAD~1..HEAD` | Commit range to verify |
| `require-all` | No | `true` | Require all commits to be signed |
| `allowed-keys` | No | `""` | Allowed GPG key IDs (comma-separated) |
| `verify-github` | No | `true` | Accept GitHub's web-flow signature |

## Outputs

| Output | Description |
|--------|-------------|
| `all-signed` | `true` if all commits are signed |
| `signed-count` | Number of signed commits |
| `unsigned-count` | Number of unsigned commits |
| `unsigned-commits` | Comma-separated list of unsigned commit SHAs |

## Usage Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  with:
    commit-range: "origin/main..HEAD"
```

### Verify PR Commits

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  id: signatures
  with:
    commit-range: "origin/${{ github.base_ref }}..HEAD"
    require-all: true

- if: steps.signatures.outputs.all-signed != 'true'
  run: |
    echo "::error::Unsigned commits detected"
    echo "Unsigned: ${{ steps.signatures.outputs.unsigned-commits }}"
```

### Allow Only Specific Keys

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  with:
    commit-range: "origin/main..HEAD"
    allowed-keys: "4AEE18F83AFDEB23,ABC123DEF456"
```

### Reject GitHub Web-Flow Signatures

```yaml
# Require commits to be signed locally, not via GitHub UI
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  with:
    commit-range: "origin/main..HEAD"
    verify-github: "false"
```

### Non-Failing Check

```yaml
- uses: arustydev/gha/actions/trust-check/verify-signatures@v1
  id: signatures
  with:
    commit-range: "origin/main..HEAD"
    require-all: "false"

- run: |
    echo "Signed: ${{ steps.signatures.outputs.signed-count }}"
    echo "Unsigned: ${{ steps.signatures.outputs.unsigned-count }}"

- if: steps.signatures.outputs.unsigned-count != '0'
  run: echo "::warning::Some commits are unsigned"
```

### Use With Trust-Based Auto-Merge

```yaml
jobs:
  verify-and-merge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: arustydev/gha/actions/trust-check/verify-signatures@v1
        id: sigs
        with:
          commit-range: "origin/main..${{ github.event.pull_request.head.sha }}"

      - uses: arustydev/gha/actions/trust-check/codeowners@v1
        id: owners
        with:
          paths: ${{ steps.changed.outputs.files }}

      - if: |
          steps.sigs.outputs.all-signed == 'true' &&
          steps.owners.outputs.is-owner == 'true'
        run: gh pr merge --auto --squash
```

## GitHub Web-Flow Signatures

When commits are made through the GitHub web interface (editing files, merging PRs, etc.), GitHub signs them with its web-flow GPG key. This action recognizes these signatures by default.

GitHub's web-flow key IDs:
- `4AEE18F83AFDEB23` - Primary web-flow key
- `B5690EEEBB952194` - noreply email key

Set `verify-github: false` to reject these and require local GPG signatures.

## Signature Types Supported

| Type | Verified |
|------|----------|
| GPG signatures | Yes |
| SSH signatures | Yes (via git verify-commit) |
| GitHub web-flow | Yes (configurable) |
| Unsigned commits | Detected, optionally fails |

## Requirements

- Repository must be checked out with history (`fetch-depth: 0` for full history)
- GPG keys must be in the git keyring for verification (GitHub-hosted runners have GitHub's keys)

## Error Conditions

| Scenario | Behavior |
|----------|----------|
| No commits in range | Passes (0 signed, 0 unsigned) |
| Unsigned commits + require-all | Fails with error |
| Invalid signature | Counts as unsigned |
| Key not in allowed-keys | Counts as unsigned |
| Can't verify (missing key) | Counts as unsigned |

## Troubleshooting

### "No signature found" for all commits

Ensure you're checking out with sufficient history:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history
```

### GPG key not trusted

GitHub-hosted runners trust GitHub's web-flow key. For custom GPG keys, you may need to import them:

```yaml
- name: Import GPG key
  run: |
    echo "${{ secrets.GPG_PUBLIC_KEY }}" | gpg --import
```
