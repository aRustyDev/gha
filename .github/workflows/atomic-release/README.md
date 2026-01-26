# Atomic Release Pipeline

Reusable GitHub Actions workflows for atomic, attestation-backed release pipelines.

## Overview

The atomic release pipeline enables per-artifact releases with cryptographic attestations that prove provenance through the entire CI/CD chain. Originally developed for Helm charts, these workflows are generic enough to support any artifact type (Rust crates, npm packages, etc.).

### Pipeline Flow

```
                    ┌───────────────────┐
                    │ validate-contribution │
                    │    (W1 equivalent)     │
                    └─────────┬─────────┘
                              │ PR to integration
                              ▼
                    ┌───────────────────┐
                    │  auto-merge-trusted  │
                    │   (trust-based)      │
                    └─────────┬─────────┘
                              │ merge to integration
                              ▼
                    ┌───────────────────┐
                    │   atomize-changes    │
                    │   (W2 equivalent)     │
                    └─────────┬─────────┘
                              │ per-artifact PRs to main
                              ▼
                    ┌───────────────────┐
                    │  validate-atomic-pr  │
                    │   (W5 equivalent)     │
                    └─────────┬─────────┘
                              │ merge to main
                              ▼
                    ┌───────────────────┐
                    │ create-release-tags  │
                    │  (W6-Tag equivalent)  │
                    └─────────┬─────────┘
                              │ creates <artifact>-v<version> tags
                              ▼
                    ┌───────────────────┐
                    │   publish-release    │
                    │   (W6 equivalent)     │
                    └───────────────────┘
```

## Workflows

### 1. validate-contribution.yml

Validates contributions with comprehensive checks and generates attestations.

**Trigger**: `workflow_call` (called by your PR workflow)

**Features**:
- Detects changed artifacts
- Runs configurable lint command
- Validates conventional commits (commitlint)
- Generates changelog preview (git-cliff)
- Creates attestations for each validation step
- Stores attestation map in PR description

**Usage**:

```yaml
# .github/workflows/validate-pr.yaml
name: Validate PR

on:
  pull_request:
    branches: [integration]

jobs:
  validate:
    uses: arustydev/gha/.github/workflows/atomic-release/validate-contribution.yml@v1
    with:
      artifact_path: "charts"
      manifest_file: "Chart.yaml"
      target_branch: "integration"
      lint_command: "ct lint --config ct.yaml --target-branch $TARGET_BRANCH"
      commitlint_config: "commitlint.config.mjs"
    secrets: inherit
```

### 2. auto-merge-trusted.yml

Enables auto-merge for trusted PRs after validation passes.

**Trigger**: `workflow_call` (typically via `workflow_run`)

**Features**:
- Trust-based verification (dependabot, CODEOWNERS)
- Commit signature verification
- Configurable merge method

**Usage**:

```yaml
# .github/workflows/auto-merge.yaml
name: Auto-Merge

on:
  workflow_run:
    workflows: ["Validate PR"]
    types: [completed]

jobs:
  auto-merge:
    if: github.event.workflow_run.conclusion == 'success'
    uses: arustydev/gha/.github/workflows/atomic-release/auto-merge-trusted.yml@v1
    with:
      validation_workflow_name: "Validate PR"
      allowed_base_branches: "integration"
      merge_method: "squash"
```

### 3. atomize-changes.yml

Creates per-artifact branches and PRs from integration to main.

**Trigger**: `workflow_call` (called on push to integration)

**Features**:
- Detects changed artifacts
- Creates/updates per-artifact branches
- Creates/updates PRs to main
- Passes through attestation lineage

**Usage**:

```yaml
# .github/workflows/atomize.yaml
name: Atomize Changes

on:
  push:
    branches: [integration]
    paths: ['charts/**']

jobs:
  atomize:
    uses: arustydev/gha/.github/workflows/atomic-release/atomize-changes.yml@v1
    with:
      artifact_path: "charts"
      manifest_file: "Chart.yaml"
      branch_prefix: "charts"
      target_branch: "main"
      source_branch: "integration"
```

### 4. validate-atomic-pr.yml

Deep validation of atomic PRs with version bumping.

**Trigger**: `workflow_call` (called on PRs to main)

**Features**:
- Validates source branch pattern
- Runs custom lint and test commands
- Bumps version based on conventional commits
- Generates/updates CHANGELOG.md
- Commits changes back to PR branch
- Cleans up source branch on merge

**Usage**:

```yaml
# .github/workflows/validate-atomic.yaml
name: Validate Atomic PR

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches: [main]

jobs:
  validate:
    uses: arustydev/gha/.github/workflows/atomic-release/validate-atomic-pr.yml@v1
    with:
      artifact_path: "charts"
      manifest_file: "Chart.yaml"
      branch_pattern: "charts/*"
      lint_command: "ct lint --config ct.yaml"
      test_command: "ct install --config ct-install.yaml"
      enable_version_bump: true
      github_app_id_secret_ref: "op://gh-shared/xauth/app/id"
      github_app_key_secret_ref: "op://gh-shared/xauth/app/private-key.pem"
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

### 5. create-release-tags.yml

Creates release tags when changes merge to main.

**Trigger**: `workflow_call` (called on push to main)

**Features**:
- Detects changed artifacts
- Reads version from manifest
- Creates annotated git tags
- Includes attestation lineage in tag message

**Usage**:

```yaml
# .github/workflows/tag-releases.yaml
name: Create Release Tags

on:
  push:
    branches: [main]
    paths: ['charts/**']

jobs:
  tag:
    uses: arustydev/gha/.github/workflows/atomic-release/create-release-tags.yml@v1
    with:
      artifact_path: "charts"
      manifest_file: "Chart.yaml"
      github_app_id_secret_ref: "op://gh-shared/xauth/app/id"
      github_app_key_secret_ref: "op://gh-shared/xauth/app/private-key.pem"
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

### 6. publish-release.yml

Packages, signs, and publishes releases.

**Trigger**: `workflow_call` (called on tag push)

**Features**:
- Validates tag format and version match
- Runs custom build command
- Generates build attestations
- Publishes to configured registry
- Signs with Cosign
- Creates GitHub Release

**Usage**:

```yaml
# .github/workflows/publish-release.yaml
name: Publish Release

on:
  push:
    tags: ['*-v*']

jobs:
  release:
    uses: arustydev/gha/.github/workflows/atomic-release/publish-release.yml@v1
    with:
      artifact_path: "charts"
      manifest_file: "Chart.yaml"
      build_command: "helm package charts/$ARTIFACT -d .release-packages/"
      publish_command: "helm push .release-packages/$ARTIFACT-$VERSION.tgz oci://ghcr.io/$REPO"
      enable_cosign: true
      create_github_release: true
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

## Supported Artifact Types

The workflows support any artifact type with a manifest file containing a version field:

| Type | artifact_path | manifest_file | Example build_command |
|------|---------------|---------------|----------------------|
| Helm | `charts` | `Chart.yaml` | `helm package charts/$ARTIFACT -d .release-packages/` |
| Rust | `crates` | `Cargo.toml` | `cargo package -p $ARTIFACT` |
| Node | `packages` | `package.json` | `npm pack --workspace=$ARTIFACT` |

## Attestation Flow

Attestations flow through the pipeline embedded in PR descriptions:

```
<!-- ATTESTATION_MAP
{"lint":"abc123","commit-validation":"def456","changelog":"ghi789"}
-->
```

Each workflow:
1. Extracts the attestation map from the source PR
2. Adds its own attestations
3. Passes the combined map to the next stage
4. Embeds the lineage in release tags and GitHub Releases

## Scripts

The pipeline includes two utility scripts:

### attestation-lib.sh

Core utilities for attestation management:
- `update_attestation_map()` - Update PR description with attestation ID
- `extract_attestation_map()` - Extract attestation map from PR
- `verify_attestation_chain()` - Verify all attestations in a map
- `detect_changed_artifacts()` - Detect changed artifacts in commit range
- `get_source_pr()` - Get PR number from merge commit
- `generate_subject_digest()` - Generate SHA256 digest for attestation

### version-bump.sh

Semantic versioning utilities:
- `determine_bump_type()` - Analyze commits for major/minor/patch
- `calculate_next_version()` - Calculate next semver
- `get_artifact_version()` - Extract version from manifest
- `update_artifact_version()` - Update version in manifest
- `generate_changelog()` - Generate changelog with git-cliff
- `bump_artifact_version()` - Main orchestrator function

## GitHub App Authentication

For operations requiring elevated permissions (pushing to protected branches, bypassing rulesets), the workflows support GitHub App authentication via 1Password:

```yaml
github_app_id_secret_ref: "op://gh-shared/xauth/app/id"
github_app_key_secret_ref: "op://gh-shared/xauth/app/private-key.pem"
```

When configured, the workflows will:
1. Load secrets from 1Password
2. Generate a GitHub App token
3. Use the token for git operations and API calls

## Versioning

Reference workflows with semantic versions:

```yaml
uses: arustydev/gha/.github/workflows/atomic-release/validate-contribution.yml@atomic-release-v1.0.0
```

Or use the latest:

```yaml
uses: arustydev/gha/.github/workflows/atomic-release/validate-contribution.yml@v1
```
