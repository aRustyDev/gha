# changelog/update

Update CHANGELOG.md with a new version section following Keep-a-Changelog format.

## Description

This action updates a CHANGELOG.md file by inserting a new version section. It handles:

- Creating the file if it doesn't exist
- Inserting after `[Unreleased]` section if present
- Inserting before existing version entries
- Preventing duplicate version entries
- Proper Keep-a-Changelog formatting

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `changelog-path` | Yes | - | Path to CHANGELOG.md file |
| `version` | Yes | - | Version number for the new section |
| `content` | Yes | - | Changelog content to insert (without version header) |
| `date` | No | Today's date | Release date (YYYY-MM-DD format) |
| `create-if-missing` | No | `true` | Create CHANGELOG.md if it does not exist |
| `compare-url` | No | - | Comparison URL to include in version header |

## Outputs

| Output | Description |
|--------|-------------|
| `updated` | Whether the file was modified (`true`/`false`) |
| `created` | Whether the file was created (`true`/`false`) |
| `path` | Full path to the changelog file |

## Usage Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    content: |
      ### Added
      - New feature X

      ### Fixed
      - Bug fix Y
```

### Combined with Generate Action

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: gen
  with:
    artifact: my-chart
    artifact-path: charts
    version: "1.3.0"

- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: charts/my-chart/CHANGELOG.md
    version: "1.3.0"
    content: ${{ steps.gen.outputs.changelog }}
```

### With Custom Date

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    date: "2024-01-15"
    content: |
      ### Added
      - Feature released on specific date
```

### With Comparison URL

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    compare-url: "https://github.com/org/repo/compare/v1.2.0...v1.3.0"
    content: |
      ### Added
      - New feature
```

This produces a header like:
```markdown
## [1.3.0](https://github.com/org/repo/compare/v1.2.0...v1.3.0) - 2024-01-15
```

### Complete Workflow Example

```yaml
name: Update Changelog

on:
  push:
    branches: [main]

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Get version
        id: version
        run: |
          VERSION=$(grep '^version:' charts/my-chart/Chart.yaml | awk '{print $2}')
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - uses: arustydev/gha/actions/changelog/generate@v1
        id: changelog
        with:
          artifact: my-chart
          artifact-path: charts
          version: ${{ steps.version.outputs.version }}

      - uses: arustydev/gha/actions/changelog/update@v1
        id: update
        with:
          changelog-path: charts/my-chart/CHANGELOG.md
          version: ${{ steps.version.outputs.version }}
          content: ${{ steps.changelog.outputs.changelog }}

      - name: Commit changes
        if: steps.update.outputs.updated == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add charts/my-chart/CHANGELOG.md
          git commit -m "docs(my-chart): update changelog for v${{ steps.version.outputs.version }}"
          git push
```

### Handling New Charts

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: charts/new-chart/CHANGELOG.md
    version: "0.1.0"
    content: |
      ### Added
      - Initial release
    create-if-missing: "true"  # Default, creates file if needed

- name: Check if new file
  run: |
    if [[ "${{ steps.update.outputs.created }}" == "true" ]]; then
      echo "Created new CHANGELOG.md"
    fi
```

## Generated File Format

When `create-if-missing` creates a new file, it follows this format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-15

### Added
- Initial release
```

## Behavior with [Unreleased] Section

If your changelog has an `[Unreleased]` section, the new version is inserted after it:

**Before:**
```markdown
## [Unreleased]

### Added
- Pending feature

## [1.2.0] - 2024-01-10
...
```

**After running with version 1.3.0:**
```markdown
## [Unreleased]

### Added
- Pending feature

## [1.3.0] - 2024-01-15

### Added
- New feature

## [1.2.0] - 2024-01-10
...
```

## Idempotency

The action is idempotent - running it multiple times with the same version will:

1. Detect the version already exists
2. Skip the update
3. Set `updated=false` in outputs
4. Log a warning

## Related Actions

- [changelog/extract-version](../extract-version) - Extract changelog for a version
- [changelog/generate](../generate) - Generate changelog from commits

## License

MIT
