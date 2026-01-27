# changelog/generate

Generate changelog entries from conventional commits using git-cliff.

## Description

This action analyzes commits since a base reference and generates a changelog entry for a specific artifact. It uses [git-cliff](https://github.com/orhun/git-cliff) for intelligent changelog generation from conventional commits, with a fallback to simple commit grouping if git-cliff is unavailable or fails.

## Features

- Filters commits by artifact path
- Groups commits by type (feat, fix, etc.)
- Supports custom git-cliff configuration
- Fallback to simple changelog if git-cliff fails
- Outputs in markdown or JSON format

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name (used to filter commits by path) |
| `artifact-path` | Yes | - | Path to artifacts directory (e.g., "charts" for Helm charts) |
| `version` | Yes | - | Version for the changelog entry (e.g., "1.3.0") |
| `base-ref` | No | `origin/main` | Base ref for commit range comparison |
| `config` | No | `cliff.toml` | Path to git-cliff configuration file |
| `output-format` | No | `markdown` | Output format: `markdown` or `json` |

## Outputs

| Output | Description |
|--------|-------------|
| `changelog` | Generated changelog content |
| `commits-analyzed` | Number of commits analyzed |

## Usage Examples

### Basic Usage

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Required for git log

- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    artifact: my-chart
    artifact-path: charts
    version: "1.3.0"

- run: echo "${{ steps.changelog.outputs.changelog }}"
```

### With Custom Base Reference

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    artifact: my-chart
    artifact-path: charts
    version: "1.3.0"
    base-ref: "origin/integration"
```

### With Custom git-cliff Config

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    artifact: my-chart
    artifact-path: charts
    version: "1.3.0"
    config: ".github/cliff.toml"
```

### Complete Workflow Example

```yaml
name: Generate Release Notes

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

      - name: Get version from Chart.yaml
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

      - name: Update CHANGELOG.md
        uses: arustydev/gha/actions/changelog/update@v1
        with:
          changelog-path: charts/my-chart/CHANGELOG.md
          version: ${{ steps.version.outputs.version }}
          content: ${{ steps.changelog.outputs.changelog }}
```

### JSON Output Format

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    artifact: my-chart
    artifact-path: charts
    version: "1.3.0"
    output-format: json

- name: Parse JSON changelog
  run: |
    echo '${{ steps.changelog.outputs.changelog }}' | jq -r .
```

## git-cliff Configuration

If you provide a custom git-cliff config, it should follow the [git-cliff format](https://git-cliff.org/docs/configuration). Example `cliff.toml`:

```toml
[changelog]
header = ""
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }}\
{% endfor %}
{% endfor %}
"""
footer = ""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
    { message = "^feat", group = "Added" },
    { message = "^fix", group = "Fixed" },
    { message = "^doc", group = "Documentation" },
    { message = "^perf", group = "Performance" },
    { message = "^refactor", group = "Refactored" },
    { message = "^style", group = "Styling" },
    { message = "^test", group = "Testing" },
    { message = "^chore", group = "Miscellaneous" },
]
```

## Fallback Behavior

If git-cliff is not available or produces no output, the action falls back to a simple changelog generator that:

1. Groups commits by conventional commit type
2. Creates `### Added` section for `feat:` commits
3. Creates `### Fixed` section for `fix:` commits
4. Creates `### Changed` section for all other commits

## Requirements

- Git repository with conventional commits
- `fetch-depth: 0` in checkout action (for full git history)

## Related Actions

- [changelog/extract-version](../extract-version) - Extract changelog for a version
- [changelog/update](../update) - Update CHANGELOG.md with new version section

## License

MIT
