# changelog/update

Update CHANGELOG.md with new section.

## Description

Updates a CHANGELOG.md file with a new version section. Inserts after the `[Unreleased]` section if present, or at the top of the changelog.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `changelog-path` | Yes | - | Path to CHANGELOG.md |
| `version` | Yes | - | Version being released |
| `content` | Yes | - | Changelog content for this version |
| `date` | No | Today's date | Release date (YYYY-MM-DD) |
| `compare-url` | No | - | GitHub comparison URL |
| `create-if-missing` | No | `true` | Create file if it doesn't exist |

## Outputs

| Output | Description |
|--------|-------------|
| `updated` | `true` if file was modified |
| `created` | `true` if file was created |
| `diff` | Diff of changes made |

## Usage

### Basic Update

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    content: |
      ### Added
      - New feature A

      ### Fixed
      - Bug fix B
```

### With Generated Content

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: generate
  with:
    from-ref: v1.2.0

- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    content: ${{ steps.generate.outputs.changelog }}
```

### With Comparison URL

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    content: ${{ steps.generate.outputs.changelog }}
    compare-url: "https://github.com/org/repo/compare/v1.2.0...v1.3.0"
```

### Custom Date

```yaml
- uses: arustydev/gha/actions/changelog/update@v1
  with:
    changelog-path: CHANGELOG.md
    version: "1.3.0"
    content: ${{ steps.generate.outputs.changelog }}
    date: "2024-01-15"
```

## File Structure

### Before

```markdown
# Changelog

## [Unreleased]

### Added
- Upcoming feature

## [1.2.0] - 2024-01-01

### Added
- Previous feature
```

### After

```markdown
# Changelog

## [Unreleased]

## [1.3.0] - 2024-01-15

### Added
- New feature A

### Fixed
- Bug fix B

## [1.2.0] - 2024-01-01

### Added
- Previous feature
```

## Idempotent Behavior

- Skips update if version section already exists
- Returns `updated: false` for duplicate versions
- Safe to run multiple times

## Comparison Links

If comparison URLs are used, the action also updates the link references at the bottom:

```markdown
[Unreleased]: https://github.com/org/repo/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/org/repo/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/org/repo/releases/tag/v1.2.0
```
