# version-bump/determine-bump

Analyze commits to determine bump type.

## Description

Analyzes conventional commit messages to determine the appropriate semantic version bump type (major, minor, or patch).

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name to analyze |
| `artifact-path` | Yes | - | Path to artifacts directory |
| `base-ref` | No | `origin/main` | Base ref for comparison |
| `type-mapping` | No | `{"feat": "minor"}` | JSON mapping of commit types to bump |
| `scopes` | No | - | Comma-separated scope filter |

## Outputs

| Output | Description |
|--------|-------------|
| `bump-type` | Determined bump type: `major`, `minor`, or `patch` |
| `has-breaking` | `true` if breaking changes detected |
| `has-features` | `true` if features detected |
| `commit-count` | Number of commits analyzed |
| `commits-json` | JSON array of analyzed commits |

## Usage

### Basic Usage

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-chart
    artifact-path: charts

- run: echo "Bump type: ${{ steps.bump.outputs.bump-type }}"
```

### Custom Type Mapping

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  with:
    artifact: my-chart
    artifact-path: charts
    type-mapping: |
      {
        "feat": "minor",
        "perf": "minor",
        "fix": "patch",
        "refactor": "patch"
      }
```

### Filter by Scope

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  with:
    artifact: my-chart
    artifact-path: charts
    scopes: "my-chart,charts"
```

## Commit Analysis Rules

| Pattern | Bump Type |
|---------|-----------|
| `feat!:` or `fix!:` | **major** |
| `BREAKING CHANGE:` in body | **major** |
| `feat:` or `feat(scope):` | **minor** |
| All other types | **patch** |

## Default Type Mapping

```json
{
  "feat": "minor",
  "fix": "patch",
  "docs": "patch",
  "style": "patch",
  "refactor": "patch",
  "perf": "patch",
  "test": "patch",
  "chore": "patch",
  "ci": "patch",
  "build": "patch"
}
```

## Commits JSON Output

```json
[
  {
    "sha": "abc1234",
    "type": "feat",
    "scope": "my-chart",
    "description": "add new feature",
    "breaking": false,
    "bump": "minor"
  },
  {
    "sha": "def5678",
    "type": "fix",
    "scope": null,
    "description": "resolve bug",
    "breaking": false,
    "bump": "patch"
  }
]
```
