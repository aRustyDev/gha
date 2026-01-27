# version-bump/update-manifest

Update version in manifest files.

## Description

Updates the version field in manifest files (YAML, TOML, JSON). Supports format auto-detection and optional lockfile updates.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `manifest-path` | Yes | - | Path to manifest file |
| `new-version` | Yes | - | Version to set |
| `version-key` | No | `version` | Key name in manifest |
| `format` | No | `auto` | Format: `yaml`, `toml`, `json`, or `auto` |
| `app-version` | No | - | Application version (for Helm charts) |
| `app-version-key` | No | `appVersion` | App version key name |
| `update-lockfile` | No | `false` | Update associated lockfile |

## Outputs

| Output | Description |
|--------|-------------|
| `updated` | `true` if file was modified |
| `previous-version` | Version before update |
| `lockfile-updated` | `true` if lockfile was updated |

## Usage

### Basic Update

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: charts/my-chart/Chart.yaml
    new-version: "1.3.0"
```

### Helm Chart with AppVersion

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: charts/my-chart/Chart.yaml
    new-version: "1.3.0"
    app-version: "2.0.0"
```

### Package.json

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: package.json
    new-version: "1.3.0"
    update-lockfile: true
```

### Cargo.toml

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: Cargo.toml
    new-version: "1.3.0"
    update-lockfile: true
```

### Explicit Format

```yaml
- uses: arustydev/gha/actions/version-bump/update-manifest@v1
  with:
    manifest-path: config.yml
    new-version: "1.3.0"
    format: yaml
```

## Supported Formats

| Format | Extensions | Tool Used |
|--------|------------|-----------|
| YAML | `.yaml`, `.yml` | `sed` (preserves formatting) |
| TOML | `.toml` | `sed` (preserves formatting) |
| JSON | `.json` | `jq` |

## Lockfile Support

| Manifest | Lockfile |
|----------|----------|
| `package.json` | `package-lock.json` |
| `Cargo.toml` | `Cargo.lock` |
| `pyproject.toml` | `poetry.lock` |

## Idempotent Behavior

- Returns `updated: false` if version already matches
- Safe to run multiple times
- No changes if version is the same
