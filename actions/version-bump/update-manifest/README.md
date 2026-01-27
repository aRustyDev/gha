# Update Manifest Version

Update the version in a manifest file supporting multiple formats (YAML, TOML, JSON).

This action modifies version fields in manifest files while preserving file formatting as much as possible.

## Usage

```yaml
# Helm Chart
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: charts/my-chart/Chart.yaml
    new-version: "1.3.0"

# Cargo.toml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: Cargo.toml
    new-version: "1.3.0"
    format: toml
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `manifest-path` | Yes | - | Path to the manifest file |
| `new-version` | Yes | - | New version to set |
| `version-key` | No | `version` | Key name for version in manifest |
| `format` | No | `auto` | File format: `yaml`, `toml`, `json`, or `auto` |
| `app-version` | No | `""` | Application version (for Helm charts, sets `appVersion`) |
| `app-version-key` | No | `appVersion` | Key name for application version |
| `update-lockfile` | No | `false` | Update associated lockfile if present |

## Outputs

| Output | Description |
|--------|-------------|
| `updated` | `true` if the file was modified |
| `previous-version` | Version before update |
| `lockfile-updated` | `true` if a lockfile was also updated |

## Supported Formats

### YAML (`.yaml`, `.yml`)

Handles both quoted and unquoted values:

```yaml
version: 1.2.3
# or
version: "1.2.3"
```

Uses `sed` for modification to preserve formatting (comments, spacing, etc.).

### TOML (`.toml`)

```toml
version = "1.2.3"
# or
[package]
version = "1.2.3"
```

### JSON (`.json`)

```json
{
  "version": "1.2.3"
}
```

Uses `jq` for modification, ensuring valid JSON output.

## Format Auto-Detection

When `format` is set to `auto` (default), the format is detected from the file extension:

| Extension | Format |
|-----------|--------|
| `.yaml`, `.yml` | yaml |
| `.toml` | toml |
| `.json` | json |

## Examples

### Helm Chart with appVersion

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: charts/my-chart/Chart.yaml
    new-version: "1.3.0"
    app-version: "2.0.0"
```

**Before:**
```yaml
version: 1.2.3
appVersion: "1.9.0"
```

**After:**
```yaml
version: 1.3.0
appVersion: "2.0.0"
```

### Cargo.toml with Lockfile Update

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: Cargo.toml
    new-version: "1.3.0"
    update-lockfile: "true"
```

This will update both `Cargo.toml` and regenerate `Cargo.lock`.

### package.json

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: package.json
    new-version: "1.3.0"
    format: json
    update-lockfile: "true"
```

### Custom Version Key

```yaml
# For a manifest with non-standard key
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: config.yaml
    new-version: "1.3.0"
    version-key: "chart_version"
```

### Complete Version Bump Pipeline

```yaml
jobs:
  bump:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

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
        id: update
        with:
          manifest-path: charts/my-chart/Chart.yaml
          new-version: ${{ steps.next.outputs.next-version }}

      - name: Commit changes
        if: steps.update.outputs.updated == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add charts/my-chart/Chart.yaml
          git commit -m "chore(my-chart): bump version to ${{ steps.next.outputs.next-version }}"
```

### Conditional Update

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  id: update
  with:
    manifest-path: Chart.yaml
    new-version: "1.3.0"

- name: Report
  run: |
    if [[ "${{ steps.update.outputs.updated }}" == "true" ]]; then
      echo "Version updated from ${{ steps.update.outputs.previous-version }} to 1.3.0"
    else
      echo "Version was already 1.3.0"
    fi
```

## Lockfile Support

When `update-lockfile: true`, the action attempts to update the corresponding lockfile:

| Manifest | Lockfile | Method |
|----------|----------|--------|
| `Cargo.toml` | `Cargo.lock` | `cargo update --offline` or `cargo generate-lockfile` |
| `package.json` | `package-lock.json` | `npm install --package-lock-only` |
| `pyproject.toml` | `poetry.lock` | `poetry lock --no-update` |

Note: Lockfile updates require the corresponding toolchain to be installed.

## Idempotency

The action is idempotent. If the version is already set to the target value:
- `updated` output will be `false`
- The file will not be modified
- No error will be raised

## Related Actions

- [determine-bump](../determine-bump/) - Analyze commits to determine bump type
- [calculate-version](../calculate-version/) - Calculate next semver from current version
