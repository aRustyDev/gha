# Version Bump Actions

Semantic versioning automation based on conventional commits.

## Overview

These actions automate semantic version management by:
- Analyzing commit messages to determine bump type
- Calculating the next version according to semver
- Updating version in manifest files

## Actions

| Action | Description |
|--------|-------------|
| [determine-bump](./determine-bump.md) | Analyze commits to determine bump type |
| [calculate-version](./calculate-version.md) | Calculate next semver version |
| [update-manifest](./update-manifest.md) | Update version in manifest files |

## Conventional Commits → Semver

| Commit Type | Example | Bump |
|-------------|---------|------|
| Breaking change | `feat!: redesign API` | **major** |
| `BREAKING CHANGE:` | `feat: new feature\n\nBREAKING CHANGE: removes old API` | **major** |
| `feat` | `feat: add new feature` | **minor** |
| `fix` | `fix: resolve bug` | **patch** |
| `docs`, `chore`, etc. | `docs: update readme` | **patch** |

## Usage Example

```yaml
jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # Get current version from manifest
      - id: current
        run: |
          version=$(yq '.version' charts/my-chart/Chart.yaml)
          echo "version=$version" >> $GITHUB_OUTPUT

      # Determine bump type from commits
      - uses: arustydev/gha/actions/version-bump/determine-bump@v1
        id: bump
        with:
          artifact: my-chart
          artifact-path: charts

      # Calculate next version
      - uses: arustydev/gha/actions/version-bump/calculate-version@v1
        id: next
        with:
          current-version: ${{ steps.current.outputs.version }}
          bump-type: ${{ steps.bump.outputs.bump-type }}

      # Update manifest
      - uses: arustydev/gha/actions/version-bump/update-manifest@v1
        with:
          manifest-path: charts/my-chart/Chart.yaml
          new-version: ${{ steps.next.outputs.next-version }}

      - run: |
          echo "Bumped from ${{ steps.current.outputs.version }}"
          echo "  to ${{ steps.next.outputs.next-version }}"
          echo "  (${{ steps.bump.outputs.bump-type }} bump)"
```

## Supported Manifest Formats

| Format | Files | Version Key |
|--------|-------|-------------|
| YAML | `Chart.yaml`, `pubspec.yaml` | `version` |
| TOML | `Cargo.toml`, `pyproject.toml` | `version` |
| JSON | `package.json`, `composer.json` | `version` |

## Pre-release Support

The `calculate-version` action supports pre-release versions:

```yaml
- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  with:
    current-version: "1.2.3"
    bump-type: minor
    pre-release: alpha
# Output: 1.3.0-alpha.0
```

Pre-release modes:
- `new` - Start new pre-release series (default)
- `increment` - Bump pre-release number (alpha.0 → alpha.1)
- `promote` - Remove pre-release suffix (1.3.0-alpha.1 → 1.3.0)
