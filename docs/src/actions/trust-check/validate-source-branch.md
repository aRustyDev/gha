# trust-check/validate-source-branch

Validate PR source branch patterns.

## Description

Validates that a PR's source branch matches allowed patterns and doesn't match denied patterns. Used to enforce branch naming conventions and prevent unauthorized branches from being merged.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `source-branch` | Yes | - | Branch name to validate |
| `allowed-pattern` | Yes | - | Comma-separated allowed patterns |
| `denied-pattern` | No | - | Comma-separated denied patterns |
| `use-regex` | No | `false` | Interpret patterns as regex |
| `fail-on-invalid` | No | `true` | Exit 1 if invalid |

## Outputs

| Output | Description |
|--------|-------------|
| `valid` | `true` if branch is valid |
| `pattern-matched` | The pattern that matched |

## Usage

### Basic Validation

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "feat/*,fix/*,chore/*"
```

### With Denied Patterns

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "*"
    denied-pattern: "main,master,release/*"
```

### Regex Patterns

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "^(feat|fix|chore)/[a-z0-9-]+$"
    use-regex: true
```

### Non-failing Validation

```yaml
- uses: arustydev/gha/actions/trust-check/validate-source-branch@v1
  id: validate
  with:
    source-branch: ${{ github.head_ref }}
    allowed-pattern: "feat/*,fix/*"
    fail-on-invalid: false

- if: steps.validate.outputs.valid != 'true'
  run: echo "::warning::Branch doesn't follow naming convention"
```

## Pattern Matching

### Glob Patterns (Default)

| Pattern | Matches | Doesn't Match |
|---------|---------|---------------|
| `feat/*` | `feat/login`, `feat/api` | `feature/login`, `feat` |
| `charts/*` | `charts/my-chart` | `chart/my-chart` |
| `release/v*` | `release/v1.0.0` | `release/1.0.0` |
| `*` | Everything | Nothing |

### Regex Patterns

| Pattern | Matches |
|---------|---------|
| `^feat/.*$` | `feat/anything` |
| `^(feat\|fix)/[a-z-]+$` | `feat/my-feature`, `fix/bug-fix` |
| `^charts/[a-z0-9-]+$` | `charts/my-chart-123` |

## Priority

Denied patterns take precedence over allowed patterns:

1. Check against denied patterns
2. If any denied pattern matches → **invalid**
3. Check against allowed patterns
4. If any allowed pattern matches → **valid**
5. Otherwise → **invalid**
