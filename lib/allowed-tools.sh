# Shared allowed tool definitions for agent scripts

# Git — specific commands, no push/reset/remote
GIT_TOOLS="Bash(git add:*) Bash(git commit:*) Bash(git diff:*) Bash(git log:*) Bash(git status:*) Bash(git branch:*) Bash(git checkout:*) Bash(git show:*) Bash(git stash:*) Bash(git rev-parse:*)"

# Shell — commands for exploring and light manipulation in the codebase
SHELL_TOOLS="Bash(ls:*) Bash(cat:*) Bash(head:*) Bash(tail:*) Bash(wc:*) Bash(mkdir:*) Bash(grep:*) Bash(find:*) Bash(tree:*) Bash(sort:*) Bash(uniq:*) Bash(diff:*) Bash(file:*) Bash(xargs:*) Bash(awk:*) Bash(sed:*) Bash(cut:*) Bash(tr:*) Bash(echo:*) Bash(tee:*)"

# Codex — peer review only
CODEX_TOOLS="Bash(codex review:*)"

# Claude Code file tools
FILE_TOOLS="Edit Write Read Glob Grep"

# Python — uv, ruff, pytest, python
PYTHON_TOOLS="Bash(uv:*) Bash(ruff:*) Bash(python:*) Bash(pytest:*)"
