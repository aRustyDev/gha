# changelog/extract-version

Extract changelog entries for a specific version from a Keep-a-Changelog format file.

## Description

This action reads a CHANGELOG.md file and extracts the section for a given version. It supports the [Keep a Changelog](https://keepachangelog.com/) format and can parse:

- Version headers with dates (`## [1.2.3] - 2024-01-15`)
- Version headers with comparison URLs (`## [1.2.3](https://github.com/org/repo/compare/v1.2.2...v1.2.3)`)
- Unreleased sections (`## [Unreleased]`)

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `changelog-path` | Yes | - | Path to CHANGELOG.md file |
| `version` | Yes | - | Version to extract (e.g., "1.2.3" or "unreleased") |
| `format` | No | `auto` | Changelog format: `keep-a-changelog`, `conventional`, or `auto` |

## Outputs

| Output | Description |
|--------|-------------|
| `content` | Changelog content for the version (without the header) |
| `found` | Whether the version section was found (`true`/`false`) |
| `date` | Release date if present in the header (YYYY-MM-DD format) |
| `compare-url` | Comparison URL if present in the header |
| `previous-version` | Previous version parsed from comparison URL |

## Usage Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/changelog/extract-version@v1
  id: changelog
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"

- run: |
    if [[ "${{ steps.changelog.outputs.found }}" == "true" ]]; then
      echo "Release notes for v1.3.0:"
      echo "${{ steps.changelog.outputs.content }}"
    else
      echo "No changelog entry found for v1.3.0"
    fi
```

### Extract Unreleased Changes

```yaml
- uses: arustydev/gha/actions/changelog/extract-version@v1
  id: unreleased
  with:
    changelog-path: CHANGELOG.md
    version: "unreleased"

- run: |
    echo "Pending changes:"
    echo "${{ steps.unreleased.outputs.content }}"
```

### Use in Release Workflow

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: arustydev/gha/actions/changelog/extract-version@v1
        id: changelog
        with:
          changelog-path: charts/my-chart/CHANGELOG.md
          version: ${{ github.event.inputs.version }}

      - name: Create GitHub Release
        if: steps.changelog.outputs.found == 'true'
        uses: softprops/action-gh-release@v1
        with:
          tag_name: v${{ github.event.inputs.version }}
          body: ${{ steps.changelog.outputs.content }}
```

### With Helm Charts

```yaml
- uses: arustydev/gha/actions/changelog/extract-version@v1
  id: changelog
  with:
    changelog-path: charts/${{ matrix.chart }}/CHANGELOG.md
    version: ${{ steps.version.outputs.new_version }}

- name: Display release date
  if: steps.changelog.outputs.date != ''
  run: echo "Released on: ${{ steps.changelog.outputs.date }}"
```

## Changelog Format

This action expects the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New feature pending release

## [1.2.3] - 2024-01-15

### Added
- New feature X

### Fixed
- Bug fix Y

## [1.2.2](https://github.com/org/repo/compare/v1.2.1...v1.2.2) - 2024-01-10

### Changed
- Updated dependency Z
```

## Related Actions

- [changelog/generate](../generate) - Generate changelog from commits
- [changelog/update](../update) - Update CHANGELOG.md with new version section

## License

MIT
