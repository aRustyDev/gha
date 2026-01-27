# changelog/extract-version

Extract changelog for specific version.

## Description

Extracts the changelog entries for a specific version from a Keep-a-Changelog format file. Useful for generating release notes.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `changelog-path` | Yes | - | Path to CHANGELOG.md |
| `version` | Yes | - | Version to extract (or `unreleased`) |
| `format` | No | `auto` | Changelog format: `keep-a-changelog`, `conventional`, `auto` |

## Outputs

| Output | Description |
|--------|-------------|
| `content` | Changelog content for version |
| `found` | `true` if version was found |
| `date` | Release date if present |
| `compare-url` | GitHub comparison URL if present |
| `previous-version` | Previous version (for comparison) |

## Usage

### Extract Specific Version

```yaml
- uses: arustydev/gha/actions/changelog/extract-version@v1
  id: notes
  with:
    changelog-path: CHANGELOG.md
    version: "1.2.0"

- run: echo "${{ steps.notes.outputs.content }}"
```

### Extract Unreleased

```yaml
- uses: arustydev/gha/actions/changelog/extract-version@v1
  id: notes
  with:
    changelog-path: CHANGELOG.md
    version: unreleased

- if: steps.notes.outputs.found == 'true'
  run: echo "Unreleased changes found"
```

### Use for Release Notes

```yaml
- uses: arustydev/gha/actions/changelog/extract-version@v1
  id: notes
  with:
    changelog-path: charts/my-chart/CHANGELOG.md
    version: ${{ github.ref_name }}

- uses: softprops/action-gh-release@v1
  with:
    body: ${{ steps.notes.outputs.content }}
```

## Supported Formats

### Keep-a-Changelog

```markdown
## [1.2.0] - 2024-01-15

### Added
- New feature

### Fixed
- Bug fix

[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
```

### Conventional Changelog

```markdown
## 1.2.0 (2024-01-15)

### Features

* add new feature ([abc1234](https://github.com/org/repo/commit/abc1234))

### Bug Fixes

* fix issue ([def5678](https://github.com/org/repo/commit/def5678))
```

## Output Examples

### Content Output

```markdown
### Added
- New feature A
- New feature B

### Fixed
- Bug fix C
```

### With Comparison URL

If the changelog includes comparison links:
```
compare-url: https://github.com/org/repo/compare/v1.1.0...v1.2.0
previous-version: 1.1.0
```
