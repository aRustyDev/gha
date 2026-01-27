# changelog/generate

Generate changelog from commits.

## Description

Generates changelog content from conventional commits using git-cliff. Falls back to simple grouping if git-cliff is unavailable.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | No | - | Artifact name to filter commits |
| `artifact-path` | No | - | Path to filter commits |
| `from-ref` | No | - | Starting ref (tag or commit) |
| `to-ref` | No | `HEAD` | Ending ref |
| `config-path` | No | - | Path to git-cliff config |
| `output-format` | No | `markdown` | Output format: `markdown` or `json` |
| `include-header` | No | `false` | Include changelog header |

## Outputs

| Output | Description |
|--------|-------------|
| `changelog` | Generated changelog content |
| `commit-count` | Number of commits processed |
| `has-changes` | `true` if any changes found |

## Usage

### Basic Generation

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    from-ref: v1.0.0
    to-ref: HEAD

- run: echo "${{ steps.changelog.outputs.changelog }}"
```

### For Specific Artifact

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    artifact: my-chart
    artifact-path: charts/my-chart
    from-ref: my-chart-v1.0.0
```

### With Custom Config

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  with:
    config-path: .github/cliff.toml
    from-ref: v1.0.0
```

### JSON Output

```yaml
- uses: arustydev/gha/actions/changelog/generate@v1
  id: changelog
  with:
    from-ref: v1.0.0
    output-format: json

- run: echo '${{ steps.changelog.outputs.changelog }}' | jq .
```

## Git-Cliff Configuration

Example `.github/cliff.toml`:

```toml
[changelog]
header = ""
body = """
{% for group, commits in commits | group_by(attribute="group") %}
### {{ group | upper_first }}
{% for commit in commits %}
- {{ commit.message | upper_first }} ([{{ commit.id | truncate(length=7, end="") }}]({{ commit.id }}))
{% endfor %}
{% endfor %}
"""
trim = true

[git]
conventional_commits = true
filter_unconventional = true
commit_parsers = [
  { message = "^feat", group = "Features" },
  { message = "^fix", group = "Bug Fixes" },
  { message = "^doc", group = "Documentation" },
  { message = "^perf", group = "Performance" },
  { message = "^refactor", group = "Refactoring" },
]
```

## Fallback Output

When git-cliff is unavailable:

```markdown
### Features
- feat: add new feature
- feat(scope): another feature

### Bug Fixes
- fix: resolve issue
- fix(scope): another fix

### Other Changes
- docs: update readme
- chore: update deps
```
