# Changelog Actions

Changelog generation and management following Keep-a-Changelog format.

## Overview

These actions automate changelog management:
- Generate changelogs from conventional commits
- Extract entries for specific versions
- Update CHANGELOG.md with new releases

## Actions

| Action | Description |
|--------|-------------|
| [extract-version](./extract-version.md) | Extract changelog for specific version |
| [generate](./generate.md) | Generate changelog from commits |
| [update](./update.md) | Update CHANGELOG.md with new section |

## Keep-a-Changelog Format

These actions follow the [Keep a Changelog](https://keepachangelog.com/) specification:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- New feature description

## [1.2.0] - 2024-01-15

### Added
- Feature A

### Fixed
- Bug B

## [1.1.0] - 2024-01-01

### Changed
- Update C

[Unreleased]: https://github.com/org/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/org/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/org/repo/releases/tag/v1.1.0
```

## Usage Example

```yaml
jobs:
  release:
    steps:
      # Generate changelog from commits since last tag
      - uses: arustydev/gha/actions/changelog/generate@v1
        id: changelog
        with:
          artifact: my-chart
          artifact-path: charts
          from-ref: ${{ steps.last-tag.outputs.tag }}
          to-ref: HEAD

      # Update CHANGELOG.md
      - uses: arustydev/gha/actions/changelog/update@v1
        with:
          changelog-path: charts/my-chart/CHANGELOG.md
          version: ${{ steps.version.outputs.next-version }}
          content: ${{ steps.changelog.outputs.changelog }}
          date: ${{ steps.date.outputs.date }}

      # Extract for release notes
      - uses: arustydev/gha/actions/changelog/extract-version@v1
        id: notes
        with:
          changelog-path: charts/my-chart/CHANGELOG.md
          version: ${{ steps.version.outputs.next-version }}

      - uses: softprops/action-gh-release@v1
        with:
          body: ${{ steps.notes.outputs.content }}
```

## Git-Cliff Integration

The `generate` action uses [git-cliff](https://git-cliff.org/) for changelog generation with fallback to simple grouping if git-cliff is unavailable.

### Custom Configuration

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  with:
    config-path: .github/cliff.toml
    artifact: my-chart
    artifact-path: charts
```

### Default Grouping

Without git-cliff, commits are grouped by type:

```markdown
### Features
- feat: add new feature

### Bug Fixes
- fix: resolve issue

### Other Changes
- docs: update readme
- chore: update deps
```
