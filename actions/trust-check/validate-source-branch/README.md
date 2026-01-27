# trust-check/validate-source-branch

Validate that a PR's source branch matches an expected pattern.

This action is used to enforce branch naming conventions and ensure PRs to protected branches come from expected source branches.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `source-branch` | Yes | - | The source branch of the PR to validate |
| `allowed-pattern` | Yes | - | Allowed branch pattern(s). Supports glob. Comma-separated for multiple. |
| `denied-pattern` | No | `""` | Denied branch pattern(s). Takes precedence over allowed. |
| `use-regex` | No | `false` | Use regex instead of glob patterns |
| `fail-on-invalid` | No | `true` | Fail the action if branch is invalid |

## Outputs

| Output | Description |
|--------|-------------|
| `valid` | `true` if branch matches allowed pattern and not denied |
| `pattern-matched` | The pattern that matched (for multiple patterns) |

## Usage Examples

### Single Pattern

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "charts/*"
```

### Multiple Patterns (comma-separated)

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "charts/*,hotfix/*,release/*"
```

### With Denied Patterns

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "feature/*,bugfix/*"
    denied-pattern: "feature/wip-*,bugfix/draft-*"
```

### Using Regex

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "^(feature|bugfix)/[a-z]+-[0-9]+.*$"
    use-regex: "true"
```

### Non-Failing Validation

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  id: branch-check
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "charts/*"
    fail-on-invalid: "false"

- if: steps.branch-check.outputs.valid != 'true'
  run: echo "::warning::Branch naming convention not followed"
```

### Protect Main Branch

```yaml
# Ensure PRs to main only come from specific branches
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "integration,release/*,hotfix/*"
    denied-pattern: "feature/*,wip/*"
```

## Pattern Syntax

### Glob Patterns (default)

| Pattern | Matches |
|---------|---------|
| `charts/*` | `charts/foo`, `charts/bar` |
| `feature/*` | `feature/add-thing`, `feature/JIRA-123` |
| `*-release` | `v1-release`, `beta-release` |
| `release/v*` | `release/v1.0`, `release/v2.0.0` |

### Regex Patterns (`use-regex: true`)

| Pattern | Matches |
|---------|---------|
| `^feature/.*$` | Any branch starting with `feature/` |
| `^(feature\|bugfix)/.*$` | Branches starting with `feature/` or `bugfix/` |
| `^release/v[0-9]+\.[0-9]+$` | `release/v1.0`, `release/v2.0` |

## Precedence

1. Denied patterns are checked first
2. If a denied pattern matches, the branch is invalid (even if an allowed pattern would match)
3. If no denied pattern matches, allowed patterns are checked
4. The first matching allowed pattern wins

## Use Cases

- Enforce atomic branch patterns (e.g., `charts/{chart-name}`)
- Protect main/production branches from direct pushes
- Ensure feature branches follow naming conventions
- Block WIP or draft branches from merging
