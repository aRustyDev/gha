# Determine Version Bump

Analyze conventional commits to determine the appropriate semantic version bump type.

This action examines commit messages in a range to determine whether the change requires a major (breaking), minor (feature), or patch (fix) bump based on [Conventional Commits](https://www.conventionalcommits.org/).

## Usage

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-chart
    artifact-path: charts
    base-ref: origin/main

- run: echo "Bump type: ${{ steps.bump.outputs.bump-type }}"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `artifact` | Yes | - | Artifact name to analyze (e.g., chart name, package name) |
| `artifact-path` | Yes | - | Path to artifacts directory (e.g., `charts`, `packages`) |
| `base-ref` | No | `origin/main` | Base ref for commit comparison |
| `type-mapping` | No | See below | JSON mapping of commit types to bump levels |
| `scopes` | No | `""` | Comma-separated list of scopes to filter commits |

### Default Type Mapping

```json
{
  "feat": "minor",
  "fix": "patch",
  "perf": "patch",
  "refactor": "patch",
  "docs": "patch",
  "style": "patch",
  "test": "patch",
  "build": "patch",
  "ci": "patch",
  "chore": "patch"
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `bump-type` | Determined bump type: `major`, `minor`, or `patch` |
| `has-breaking` | `true` if breaking changes were detected |
| `has-features` | `true` if new features were detected |
| `commit-count` | Number of commits analyzed |
| `commits-json` | JSON array of analyzed commits with type and message |

## Bump Type Detection

The action determines bump type using the following rules (in order of priority):

### Major (Breaking Change)

A **major** bump is triggered when:
- A commit contains `!` before the colon: `feat!: breaking change` or `fix(scope)!: breaking`
- A commit contains `BREAKING CHANGE` or `BREAKING-CHANGE` anywhere in the message

### Minor (New Feature)

A **minor** bump is triggered when:
- A commit uses the `feat` type: `feat: add new capability`
- A commit type maps to `minor` in the type-mapping

### Patch (Bug Fix / Other)

A **patch** bump is used for:
- `fix`, `perf`, `refactor`, `docs`, `style`, `test`, `build`, `ci`, `chore` commits
- Any unrecognized commit type
- When no commits are found

## Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: cloudflared
    artifact-path: charts

- name: Show Results
  run: |
    echo "Bump type: ${{ steps.bump.outputs.bump-type }}"
    echo "Has breaking: ${{ steps.bump.outputs.has-breaking }}"
    echo "Commit count: ${{ steps.bump.outputs.commit-count }}"
```

### Custom Type Mapping

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-lib
    artifact-path: packages
    type-mapping: |
      {
        "feat": "minor",
        "fix": "patch",
        "perf": "minor",
        "refactor": "patch"
      }
```

### Using with calculate-version

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-chart
    artifact-path: charts

- uses: arustydev/gha/actions/version-bump/calculate-version@v1
  id: version
  with:
    current-version: "1.2.3"
    bump-type: ${{ steps.bump.outputs.bump-type }}

- run: echo "Next version: ${{ steps.version.outputs.next-version }}"
```

### With Different Base Ref

```yaml
- uses: arustydev/gha/actions/version-bump/determine-bump@v1
  id: bump
  with:
    artifact: my-chart
    artifact-path: charts
    base-ref: origin/integration
```

## Commits JSON Output

The `commits-json` output provides detailed information about each commit:

```json
[
  {
    "hash": "abc1234",
    "message": "feat(auth): add OAuth2 support",
    "type": "feat",
    "scope": "auth",
    "breaking": false
  },
  {
    "hash": "def5678",
    "message": "fix!: resolve critical bug",
    "type": "fix",
    "scope": "",
    "breaking": true
  }
]
```

## Related Actions

- [calculate-version](../calculate-version/) - Calculate next semver from current version and bump type
- [update-manifest](../update-manifest/) - Update version in manifest files
