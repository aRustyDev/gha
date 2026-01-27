# Calculate Version

Calculate the next semantic version based on current version and bump type.

This is a pure function that takes a version and bump type, and returns the incremented version following [SemVer](https://semver.org/) specification.

## Usage

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: version
  with:
    current-version: "1.2.3"
    bump-type: minor

- run: echo "Next version: ${{ steps.version.outputs.next-version }}"
# Output: 1.3.0
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `current-version` | Yes | - | Current semver version (e.g., `1.2.3` or `v1.2.3`) |
| `bump-type` | Yes | - | Bump type: `major`, `minor`, or `patch` |
| `pre-release` | No | `""` | Pre-release identifier (e.g., `alpha`, `beta`, `rc`) |
| `pre-release-bump` | No | `new` | How to handle pre-release: `increment`, `promote`, or `new` |
| `build-metadata` | No | `""` | Build metadata to append after `+` |

## Outputs

| Output | Description |
|--------|-------------|
| `next-version` | Calculated next version (without `v` prefix) |
| `major` | Major version component |
| `minor` | Minor version component |
| `patch` | Patch version component |
| `is-pre-release` | `true` if the version is a pre-release |
| `pre-release-id` | Pre-release identifier (e.g., `alpha.1`) |

## Version Bump Examples

### Standard Bumps

| Current | Bump Type | Result |
|---------|-----------|--------|
| `1.2.3` | `patch` | `1.2.4` |
| `1.2.3` | `minor` | `1.3.0` |
| `1.2.3` | `major` | `2.0.0` |
| `0.1.0` | `major` | `1.0.0` |
| `v1.2.3` | `patch` | `1.2.4` |

### Pre-release Handling

| Current | Bump | Pre-release | Pre-release Bump | Result |
|---------|------|-------------|------------------|--------|
| `1.2.3` | `minor` | `alpha` | `new` | `1.3.0-alpha.1` |
| `1.3.0-alpha.1` | `minor` | `alpha` | `increment` | `1.3.0-alpha.2` |
| `1.3.0-alpha.2` | `minor` | `beta` | `new` | `1.3.0-beta.1` |
| `1.3.0-beta.1` | `minor` | - | `promote` | `1.3.0` |

### Build Metadata

| Current | Bump | Build Metadata | Result |
|---------|------|----------------|--------|
| `1.2.3` | `patch` | `build.456` | `1.2.4+build.456` |
| `1.2.3+build.123` | `patch` | `build.456` | `1.2.4+build.456` |

## Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: version
  with:
    current-version: "1.2.3"
    bump-type: minor

- run: |
    echo "Next: ${{ steps.version.outputs.next-version }}"
    echo "Major: ${{ steps.version.outputs.major }}"
    echo "Minor: ${{ steps.version.outputs.minor }}"
    echo "Patch: ${{ steps.version.outputs.patch }}"
```

### Pre-release Versions

```yaml
# Start alpha pre-release
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: alpha
  with:
    current-version: "1.2.3"
    bump-type: minor
    pre-release: alpha

- run: echo "${{ steps.alpha.outputs.next-version }}"
# Output: 1.3.0-alpha.1

# Increment alpha
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: alpha2
  with:
    current-version: "1.3.0-alpha.1"
    bump-type: minor
    pre-release: alpha
    pre-release-bump: increment

- run: echo "${{ steps.alpha2.outputs.next-version }}"
# Output: 1.3.0-alpha.2

# Promote to stable
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: stable
  with:
    current-version: "1.3.0-alpha.2"
    bump-type: minor
    pre-release-bump: promote

- run: echo "${{ steps.stable.outputs.next-version }}"
# Output: 1.3.0
```

### With Build Metadata

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: version
  with:
    current-version: "1.2.3"
    bump-type: patch
    build-metadata: "build.${{ github.run_number }}"

- run: echo "${{ steps.version.outputs.next-version }}"
# Output: 1.2.4+build.123
```

### Complete Pipeline with determine-bump

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-chart
    artifact-path: charts

- name: Get current version
  id: current
  run: |
    VERSION=$(grep '^version:' charts/my-chart/Chart.yaml | awk '{print $2}')
    echo "version=$VERSION" >> "$GITHUB_OUTPUT"

- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: next
  with:
    current-version: ${{ steps.current.outputs.version }}
    bump-type: ${{ steps.bump.outputs.bump-type }}

- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: charts/my-chart/Chart.yaml
    new-version: ${{ steps.next.outputs.next-version }}
```

## Related Actions

- [determine-bump](../determine-bump/) - Analyze commits to determine bump type
- [update-manifest](../update-manifest/) - Update version in manifest files
