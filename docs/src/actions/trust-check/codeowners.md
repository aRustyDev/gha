# trust-check/codeowners

Verify actor in CODEOWNERS.

## Description

Checks if the workflow actor (user triggering the workflow) is listed as a code owner for specified paths. Supports individual users, teams, and glob patterns.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `actor` | No | `github.actor` | Username to check |
| `paths` | No | - | Comma-separated paths to check ownership |
| `codeowners-path` | No | `.github/CODEOWNERS` | Path to CODEOWNERS file |
| `token` | No | `github.token` | Token for team membership checks |

## Outputs

| Output | Description |
|--------|-------------|
| `is-owner` | `true` if actor is an owner |
| `matched-pattern` | CODEOWNERS pattern that matched |
| `owners` | Comma-separated list of owners for path |

## Usage

### Basic Check

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  id: owner
  with:
    paths: charts/my-chart

- if: steps.owner.outputs.is-owner != 'true'
  run: |
    echo "User is not a code owner for this path"
    exit 1
```

### Check Specific User

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  with:
    actor: some-user
    paths: charts/my-chart
```

### Multiple Paths

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  with:
    paths: "charts/chart-a,charts/chart-b,docs/"
```

## CODEOWNERS Format

```
# Default owners for everything
* @org/maintainers

# Specific directory owners
/charts/ @org/chart-maintainers
/charts/critical-chart/ @org/senior-maintainers @lead-dev

# File pattern owners
*.md @org/docs-team
/docs/**/*.md @tech-writer
```

## Matching Rules

Per GitHub's CODEOWNERS specification:

1. **Last match wins** - Later rules override earlier ones
2. **Patterns are relative** to repository root
3. **Glob patterns** supported (`*`, `**`, `?`)

## Team Membership

When the owner is a team (`@org/team`):

1. Action queries GitHub API for team members
2. Checks if actor is in the team
3. Requires `read:org` scope for private org teams

## Required Permissions

```yaml
permissions:
  contents: read    # Read CODEOWNERS file
  # For team membership checks:
  # Token needs read:org scope
```
