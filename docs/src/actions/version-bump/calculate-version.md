# version-bump/calculate-version

Calculate next semver version.

## Description

Calculates the next semantic version based on the current version and bump type. Supports pre-release versions and build metadata.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `current-version` | Yes | - | Current semver version |
| `bump-type` | Yes | - | Bump type: `major`, `minor`, or `patch` |
| `pre-release` | No | - | Pre-release identifier (e.g., `alpha`, `beta`, `rc`) |
| `pre-release-bump` | No | `new` | Pre-release mode: `new`, `increment`, `promote` |
| `build-metadata` | No | - | Build metadata to append |

## Outputs

| Output | Description |
|--------|-------------|
| `next-version` | Calculated next version |
| `major` | Major version component |
| `minor` | Minor version component |
| `patch` | Patch version component |
| `is-pre-release` | `true` if result is pre-release |
| `pre-release-id` | Pre-release identifier if present |

## Usage

### Basic Version Bump

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: version
  with:
    current-version: "1.2.3"
    bump-type: minor

- run: echo "Next: ${{ steps.version.outputs.next-version }}"
# Output: Next: 1.3.0
```

### Major Version Bump

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  with:
    current-version: "1.2.3"
    bump-type: major
# Output: 2.0.0
```

### Pre-release Version

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  with:
    current-version: "1.2.3"
    bump-type: minor
    pre-release: alpha
# Output: 1.3.0-alpha.0
```

### Increment Pre-release

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  with:
    current-version: "1.3.0-alpha.0"
    bump-type: patch
    pre-release: alpha
    pre-release-bump: increment
# Output: 1.3.0-alpha.1
```

### Promote Pre-release

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  with:
    current-version: "1.3.0-alpha.5"
    bump-type: patch
    pre-release-bump: promote
# Output: 1.3.0
```

### With Build Metadata

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  with:
    current-version: "1.2.3"
    bump-type: patch
    build-metadata: "build.123"
# Output: 1.2.4+build.123
```

## Version Parsing

The action handles various input formats:

| Input | Parsed As |
|-------|-----------|
| `1.2.3` | 1.2.3 |
| `v1.2.3` | 1.2.3 (v prefix stripped) |
| `1.2.3-alpha.0` | 1.2.3 with pre-release |
| `1.2.3+build` | 1.2.3 with metadata |

## Pre-release Modes

| Mode | Description | Example |
|------|-------------|---------|
| `new` | Start new pre-release series | 1.2.3 → 1.3.0-alpha.0 |
| `increment` | Bump pre-release number | 1.3.0-alpha.0 → 1.3.0-alpha.1 |
| `promote` | Remove pre-release suffix | 1.3.0-alpha.1 → 1.3.0 |
