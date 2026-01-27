# trust-check/codeowners

Verify that the workflow actor is listed in CODEOWNERS for relevant paths.

This action parses the CODEOWNERS file and checks if the specified actor (defaulting to the workflow trigger) is an owner for the given paths. Supports both direct user matches and team membership verification.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `actor` | No | `github.actor` | GitHub username to verify |
| `paths` | No | `""` | Paths to check ownership for (comma-separated) |
| `codeowners-path` | No | `.github/CODEOWNERS` | Path to CODEOWNERS file |
| `token` | No | `github.token` | GitHub token for team membership checks |

## Outputs

| Output | Description |
|--------|-------------|
| `is-owner` | `true` if actor is a codeowner for the paths |
| `matched-pattern` | CODEOWNERS pattern that matched |
| `owners` | Comma-separated list of owners for the matched pattern |

## Usage Examples

### Basic Usage

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  id: codeowners
  with:
    paths: "charts/my-chart"

- if: steps.codeowners.outputs.is-owner == 'true'
  run: echo "Actor is authorized to modify charts/my-chart"
```

### Check Specific Actor

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  id: codeowners
  with:
    actor: ${{ github.event.pull_request.user.login }}
    paths: ${{ steps.changed.outputs.files }}
```

### Multiple Paths

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  id: codeowners
  with:
    paths: "charts/app1,charts/app2,.github/workflows"
```

### Check If Actor Is Any Codeowner

```yaml
# Without paths, checks if actor is listed anywhere in CODEOWNERS
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  id: codeowners

- if: steps.codeowners.outputs.is-owner == 'true'
  run: echo "Actor is a codeowner in this repository"
```

### Custom CODEOWNERS Location

```yaml
- uses: arustydev/gha/actions/trust-check/codeowners@v1
  with:
    codeowners-path: "docs/CODEOWNERS"
    paths: "docs/"
```

### Gate Auto-Merge on Ownership

```yaml
jobs:
  auto-merge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: arustydev/gha/actions/trust-check/codeowners@v1
        id: owner-check
        with:
          paths: ${{ steps.changed-files.outputs.all_changed_files }}

      - if: steps.owner-check.outputs.is-owner == 'true'
        run: gh pr merge --auto --squash "${{ github.event.pull_request.number }}"
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## CODEOWNERS Format Support

The action supports standard CODEOWNERS syntax:

```
# Comment lines are ignored

# Pattern with users
*.js @user1 @user2

# Pattern with teams
/charts/ @myorg/helm-maintainers

# Pattern with mixed
/docs/ @user1 @myorg/docs-team

# Wildcard (matches everything)
* @default-reviewers

# Directory pattern
/src/api/ @backend-team

# File extension pattern
*.md @docs-team
```

## Pattern Matching

| Pattern | Matches |
|---------|---------|
| `*` | All files |
| `*.js` | All JavaScript files |
| `/docs/` | Everything under `/docs/` |
| `/src/api/` | Everything under `/src/api/` |
| `charts/*` | Direct children of `charts/` |
| `charts/**` | All descendants of `charts/` |

Note: Per CODEOWNERS specification, the last matching pattern wins when multiple patterns match a path.

## Team Membership

When a CODEOWNERS entry uses a team (e.g., `@myorg/my-team`), the action queries the GitHub API to verify team membership. This requires:

- The token to have `read:org` scope for private organizations
- The actor to be a direct member of the team (not just organization member)

## Limitations

- Email patterns in CODEOWNERS are detected but not fully verified
- Nested team membership is not recursively checked
- The action requires the repository to be checked out to read CODEOWNERS
