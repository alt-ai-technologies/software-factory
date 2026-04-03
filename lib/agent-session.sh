# Shared helpers for .agent-session marker files and tab titles

AGENT_SESSION_FILE=".agent-session"

# Write or update the .agent-session marker file in a given directory.
# Usage: write_agent_session <dir> <key=value> [key=value ...]
# Example: write_agent_session /path/to/clone state=running agent=build pid=$$
write_agent_session() {
    local dir="$1"; shift
    local file="${dir}/${AGENT_SESSION_FILE}"
    local tmpfile="${file}.tmp"

    # Start from existing file or empty
    if [[ -f "$file" ]]; then
        cp "$file" "$tmpfile"
    else
        : > "$tmpfile"
    fi

    # For each key=value override, remove old line for that key, append new
    for pair in "$@"; do
        local key="${pair%%=*}"
        grep -v "^${key}=" "$tmpfile" > "${tmpfile}.2" 2>/dev/null || true
        mv "${tmpfile}.2" "$tmpfile"
        echo "$pair" >> "$tmpfile"
    done

    mv "$tmpfile" "$file"
}

# Read .agent-session into shell variables prefixed with SESSION_.
# Usage: eval "$(read_agent_session /path/to/clone)"
# Then access: $SESSION_state, $SESSION_agent, $SESSION_repo, etc.
read_agent_session() {
    local dir="$1"
    local file="${dir}/${AGENT_SESSION_FILE}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" == \#* ]] && continue
        printf 'SESSION_%s=%q\n' "$key" "$value"
    done < "$file"
}

# Check if a PID is still alive.
# Returns 0 if alive, 1 if dead.
is_pid_alive() {
    local pid="$1"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Set the terminal tab title.
# Works in Terminal.app, iTerm2, and most xterm-compatible terminals.
set_tab_title() {
    local title="$1"
    printf '\033]1;%s\007' "$title"
}

# Reset the terminal tab title to default (empty).
reset_tab_title() {
    printf '\033]1;\007'
}
