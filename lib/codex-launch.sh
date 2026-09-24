#!/usr/bin/env bash
set -euo pipefail

# Resolve and validate a role's inputs before any repository operations.
# Sets CODEX_TARGET_DIR and CODEX_PROMPT_FILE for launch_codex.
prepare_codex_session() {
    local role="$1"
    local target_dir="$2"
    local factory_dir workspace
    factory_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    workspace="$(dirname "$factory_dir")"

    if [[ ! -d "$target_dir" ]] && [[ -d "${workspace}/${target_dir}" ]]; then
        target_dir="${workspace}/${target_dir}"
    fi

    if [[ ! -d "$target_dir" ]]; then
        echo "ERROR: Directory not found at $target_dir" >&2
        return 1
    fi

    CODEX_TARGET_DIR="$(cd "$target_dir" && pwd)"
    CODEX_PROMPT_FILE="${factory_dir}/prompts/codex/${role}.md"

    if [[ ! -f "$CODEX_PROMPT_FILE" ]]; then
        echo "ERROR: Prompt not found at $CODEX_PROMPT_FILE" >&2
        return 1
    fi

    if ! command -v codex >/dev/null 2>&1; then
        echo "ERROR: codex is not installed or is not on PATH" >&2
        return 127
    fi
}

# Use the normal Codex configuration. exec preserves its exit status and signals.
launch_codex() {
    local role_prompt initial_prompt
    role_prompt="$(cat "$CODEX_PROMPT_FILE")"
    printf -v initial_prompt '%s\n\n## Opening task\n\n%s' "$role_prompt" "$1"

    echo "==> Starting Codex session in $CODEX_TARGET_DIR"
    echo "    Prompt: $CODEX_PROMPT_FILE"
    echo ""

    cd "$CODEX_TARGET_DIR"
    exec codex "$initial_prompt"
}
