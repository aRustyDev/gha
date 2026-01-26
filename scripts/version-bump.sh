#!/usr/bin/env bash
# version-bump.sh - Semantic versioning and changelog generation
#
# This script analyzes conventional commits to determine the appropriate
# semver bump and generates/updates the artifact's CHANGELOG.md.
#
# Usage:
#   source scripts/version-bump.sh
#
# Required tools:
#   - git-cliff (for changelog generation, optional fallback to git log)
#
# Environment variables:
#   GITHUB_OUTPUT - GitHub Actions output file
#   GITHUB_REPOSITORY - owner/repo format
#   ARTIFACT_PATH - Path to artifacts (default: "charts")
#   MANIFEST_FILE - Manifest file name (default: "Chart.yaml")

set -euo pipefail

# Default configuration (can be overridden via environment)
: "${ARTIFACT_PATH:=charts}"
: "${MANIFEST_FILE:=Chart.yaml}"

#######################################
# Determine the semver bump type from conventional commits
#
# Arguments:
#   $1 - artifact: Artifact name to analyze
#   $2 - base_ref: Base branch/ref for comparison (default: origin/main)
#   $3 - artifact_path: Path to artifacts (optional)
#
# Outputs:
#   Bump type: "major", "minor", or "patch"
#######################################
determine_bump_type() {
    local artifact="$1"
    local base_ref="${2:-origin/main}"
    local artifact_path="${3:-${ARTIFACT_PATH:-}}"
    local full_path="${artifact_path}/${artifact}"

    # Get commits affecting this artifact since base
    local commits
    commits=$(git log --oneline "$base_ref"..HEAD -- "$full_path" 2>/dev/null || true)

    if [[ -z "$commits" ]]; then
        echo "patch"
        return 0
    fi

    # Check for breaking changes (major bump)
    if echo "$commits" | grep -qiE '(BREAKING[ -]CHANGE|!:)'; then
        echo "major"
        return 0
    fi

    # Check for features (minor bump)
    if echo "$commits" | grep -qE '^[a-f0-9]+ feat'; then
        echo "minor"
        return 0
    fi

    # Default to patch
    echo "patch"
}

#######################################
# Calculate the next version based on bump type
#
# Arguments:
#   $1 - current_version: Current semver (e.g., "1.2.3")
#   $2 - bump_type: "major", "minor", or "patch"
#
# Outputs:
#   Next version string
#######################################
calculate_next_version() {
    local current_version="$1"
    local bump_type="$2"

    # Remove any leading 'v'
    current_version="${current_version#v}"

    # Parse version components
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current_version"

    # Handle pre-release suffixes (e.g., 1.2.3-beta.1)
    patch="${patch%%-*}"

    case "$bump_type" in
        major)
            echo "$((major + 1)).0.0"
            ;;
        minor)
            echo "$major.$((minor + 1)).0"
            ;;
        patch)
            echo "$major.$minor.$((patch + 1))"
            ;;
        *)
            echo "::error::Unknown bump type: $bump_type"
            return 1
            ;;
    esac
}

#######################################
# Get current version from manifest file
#
# Supports common manifest formats:
#   - Chart.yaml (Helm): version: X.Y.Z
#   - Cargo.toml (Rust): version = "X.Y.Z"
#   - package.json (Node): "version": "X.Y.Z"
#
# Arguments:
#   $1 - artifact: Artifact name
#   $2 - artifact_path: Path to artifacts (optional)
#   $3 - manifest_file: Manifest file name (optional)
#
# Outputs:
#   Current version string
#######################################
get_artifact_version() {
    local artifact="$1"
    local artifact_path="${2:-${ARTIFACT_PATH:-}}"
    local manifest_file="${3:-${MANIFEST_FILE:-}}"
    local manifest_path="${artifact_path}/${artifact}/${manifest_file}"

    if [[ ! -f "$manifest_path" ]]; then
        echo "::error::Manifest not found: $manifest_path"
        return 1
    fi

    local version=""

    case "$manifest_file" in
        Chart.yaml|Chart.yml)
            version=$(grep '^version:' "$manifest_path" | awk '{print $2}' | tr -d '"' | tr -d "'")
            ;;
        Cargo.toml)
            version=$(grep '^version' "$manifest_path" | head -1 | sed 's/.*= *"\([^"]*\)".*/\1/')
            ;;
        package.json)
            version=$(jq -r '.version' "$manifest_path")
            ;;
        *)
            # Generic: try YAML-style first, then TOML-style
            version=$(grep -E '^version[=:]' "$manifest_path" | head -1 | sed 's/.*[=:] *"\?\([^"]*\)"\?.*/\1/' | tr -d '"' | tr -d "'" | xargs)
            ;;
    esac

    if [[ -z "$version" || "$version" == "null" ]]; then
        echo "::error::Could not extract version from $manifest_path"
        return 1
    fi

    echo "$version"
}

#######################################
# Update version in manifest file
#
# Arguments:
#   $1 - artifact: Artifact name
#   $2 - new_version: New version to set
#   $3 - artifact_path: Path to artifacts (optional)
#   $4 - manifest_file: Manifest file name (optional)
#
# Returns:
#   0 on success, 1 on failure
#######################################
update_artifact_version() {
    local artifact="$1"
    local new_version="$2"
    local artifact_path="${3:-${ARTIFACT_PATH:-}}"
    local manifest_file="${4:-${MANIFEST_FILE:-}}"
    local manifest_path="${artifact_path}/${artifact}/${manifest_file}"

    if [[ ! -f "$manifest_path" ]]; then
        echo "::error::Manifest not found: $manifest_path"
        return 1
    fi

    case "$manifest_file" in
        Chart.yaml|Chart.yml)
            # Use sed for portability (yq changes formatting)
            sed -i "s/^version: .*/version: $new_version/" "$manifest_path"
            ;;
        Cargo.toml)
            # Update first version line in Cargo.toml
            sed -i "0,/^version = .*/s//version = \"$new_version\"/" "$manifest_path"
            ;;
        package.json)
            # Use jq for JSON
            local tmp
            tmp=$(mktemp)
            jq ".version = \"$new_version\"" "$manifest_path" > "$tmp"
            mv "$tmp" "$manifest_path"
            ;;
        *)
            # Generic: try sed for YAML/TOML style
            sed -i "s/^version[=:] .*/version: $new_version/" "$manifest_path"
            ;;
    esac

    echo "::notice::Updated $manifest_path to version $new_version"
}

#######################################
# Generate changelog using git-cliff
#
# Arguments:
#   $1 - artifact: Artifact name
#   $2 - new_version: Version for the changelog entry
#   $3 - base_ref: Base branch/ref for comparison (default: origin/main)
#   $4 - artifact_path: Path to artifacts (optional)
#   $5 - cliff_config: Path to git-cliff config (optional)
#
# Returns:
#   0 on success, 1 on failure
#######################################
generate_changelog() {
    local artifact="$1"
    local new_version="$2"
    local base_ref="${3:-origin/main}"
    local artifact_path="${4:-${ARTIFACT_PATH:-}}"
    local cliff_config="${5:-cliff.toml}"
    local full_path="${artifact_path}/${artifact}"
    local changelog_file="${full_path}/CHANGELOG.md"

    echo "::group::Generating changelog for $artifact v$new_version"

    # Create changelog if it doesn't exist
    if [[ ! -f "$changelog_file" ]]; then
        cat > "$changelog_file" << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

EOF
        echo "::notice::Created new CHANGELOG.md for $artifact"
    fi

    # Generate changelog entry for unreleased changes
    local changelog_entry=""

    # Try git-cliff first
    if command -v git-cliff &>/dev/null; then
        local cliff_args=(
            --unreleased
            --tag "${artifact}-v${new_version}"
            --strip header
            --strip footer
        )

        # Add config if it exists
        if [[ -f "$cliff_config" ]]; then
            cliff_args+=(--config "$cliff_config")
        fi

        # Add include-path for artifact-specific commits
        cliff_args+=(--include-path "${full_path}/**")

        changelog_entry=$(git-cliff "${cliff_args[@]}" 2>/dev/null || true)
    fi

    if [[ -z "$changelog_entry" || "$changelog_entry" == *"No commits"* ]]; then
        # Fallback: generate simple entry from commits
        echo "::warning::git-cliff produced no output, generating simple changelog"
        local commits
        commits=$(git log --oneline "$base_ref"..HEAD -- "$full_path" 2>/dev/null | head -20)

        if [[ -n "$commits" ]]; then
            changelog_entry="## [$new_version] - $(date +%Y-%m-%d)

### Changed
$(echo "$commits" | sed 's/^[a-f0-9]* /- /')
"
        else
            changelog_entry="## [$new_version] - $(date +%Y-%m-%d)

### Changed
- Version bump
"
        fi
    fi

    # Prepend new entry after the header (after first blank line following header)
    local temp_file
    temp_file=$(mktemp)

    # Find where to insert (after the header section)
    awk -v entry="$changelog_entry" '
        /^# Changelog/ { header=1 }
        header && /^$/ && !inserted {
            print
            print entry
            inserted=1
            next
        }
        { print }
    ' "$changelog_file" > "$temp_file"

    mv "$temp_file" "$changelog_file"

    echo "::notice::Updated CHANGELOG.md for $artifact"
    echo "::endgroup::"
}

#######################################
# Check if version was already bumped in this PR
#
# Arguments:
#   $1 - artifact: Artifact name
#   $2 - base_ref: Base branch/ref for comparison
#   $3 - artifact_path: Path to artifacts (optional)
#   $4 - manifest_file: Manifest file name (optional)
#
# Returns:
#   0 if already bumped, 1 if not
#######################################
is_version_already_bumped() {
    local artifact="$1"
    local base_ref="${2:-origin/main}"
    local artifact_path="${3:-${ARTIFACT_PATH:-}}"
    local manifest_file="${4:-${MANIFEST_FILE:-}}"
    local manifest_path="${artifact_path}/${artifact}/${manifest_file}"

    # Check if manifest version differs from base
    local current_version base_version
    current_version=$(get_artifact_version "$artifact" "$artifact_path" "$manifest_file")
    base_version=$(git show "$base_ref:$manifest_path" 2>/dev/null | grep -E '^version[=:]' | head -1 | sed 's/.*[=:] *"\?\([^"]*\)"\?.*/\1/' | tr -d '"' | tr -d "'" | xargs || echo "")

    if [[ -z "$base_version" ]]; then
        # New artifact, no base version
        return 1
    fi

    if [[ "$current_version" != "$base_version" ]]; then
        echo "::notice::Version already bumped: $base_version -> $current_version"
        return 0
    fi

    return 1
}

#######################################
# Main function to bump version and generate changelog
#
# Arguments:
#   $1 - artifact: Artifact name
#   $2 - base_ref: Base branch/ref for comparison (default: origin/main)
#   $3 - artifact_path: Path to artifacts (optional)
#   $4 - manifest_file: Manifest file name (optional)
#
# Outputs (via GITHUB_OUTPUT):
#   bumped: "true" or "false"
#   version: New version string
#   bump_type: "major", "minor", "patch", or "none"
#######################################
bump_artifact_version() {
    local artifact="$1"
    local base_ref="${2:-origin/main}"
    local artifact_path="${3:-${ARTIFACT_PATH:-}}"
    local manifest_file="${4:-${MANIFEST_FILE:-}}"

    echo "::group::Processing version bump for $artifact"

    # Check if already bumped
    if is_version_already_bumped "$artifact" "$base_ref" "$artifact_path" "$manifest_file"; then
        local current_version
        current_version=$(get_artifact_version "$artifact" "$artifact_path" "$manifest_file")
        echo "bumped=false" >> "${GITHUB_OUTPUT:-/dev/null}"
        echo "version=$current_version" >> "${GITHUB_OUTPUT:-/dev/null}"
        echo "bump_type=none" >> "${GITHUB_OUTPUT:-/dev/null}"
        echo "::endgroup::"
        return 0
    fi

    # Determine bump type
    local bump_type
    bump_type=$(determine_bump_type "$artifact" "$base_ref" "$artifact_path")
    echo "::notice::Determined bump type: $bump_type"

    # Get current and calculate next version
    local current_version next_version
    current_version=$(get_artifact_version "$artifact" "$artifact_path" "$manifest_file")
    next_version=$(calculate_next_version "$current_version" "$bump_type")
    echo "::notice::Version bump: $current_version -> $next_version"

    # Update manifest
    update_artifact_version "$artifact" "$next_version" "$artifact_path" "$manifest_file"

    # Generate changelog
    generate_changelog "$artifact" "$next_version" "$base_ref" "$artifact_path"

    # Output results
    echo "bumped=true" >> "${GITHUB_OUTPUT:-/dev/null}"
    echo "version=$next_version" >> "${GITHUB_OUTPUT:-/dev/null}"
    echo "bump_type=$bump_type" >> "${GITHUB_OUTPUT:-/dev/null}"

    echo "::endgroup::"
}

# Backward compatibility alias for Helm charts
bump_chart_version() {
    local chart="$1"
    local base_ref="${2:-origin/main}"
    bump_artifact_version "$chart" "$base_ref" "charts" "Chart.yaml"
}

# Export functions for use in workflows
export -f determine_bump_type
export -f calculate_next_version
export -f get_artifact_version
export -f update_artifact_version
export -f generate_changelog
export -f is_version_already_bumped
export -f bump_artifact_version
export -f bump_chart_version
