#!/usr/bin/env bash
set -euo pipefail

# Shared by the Claude and Codex merge planners. Does not perform the merge.
merge_preflight() {
    local clone_dir="$1"
    local branch_a="$2"
    local branch_b="$3"
    local branch

    if [[ -n "$(git -C "$clone_dir" status --porcelain)" ]]; then
        echo "ERROR: Working tree is not clean in $clone_dir"
        echo "       Commit or stash your changes before running plan-merge."
        return 1
    fi

    if ! git -C "$clone_dir" diff --cached --quiet; then
        echo "ERROR: Staged changes exist in $clone_dir"
        echo "       Commit your staged changes before running plan-merge."
        return 1
    fi

    echo "==> Fetching origin..."
    git -C "$clone_dir" fetch origin

    for branch in "$branch_a" "$branch_b"; do
        if git -C "$clone_dir" rev-parse --verify "$branch" >/dev/null 2>&1; then
            continue
        elif git -C "$clone_dir" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
            echo "==> Creating local tracking branch for $branch"
            git -C "$clone_dir" branch "$branch" "origin/$branch"
        else
            echo "ERROR: Branch '$branch' not found locally or on origin"
            return 1
        fi
    done

    echo "==> Pre-flight checks passed"
}
