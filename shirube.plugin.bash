#!/usr/bin/env bash
# SHIRUBE - fzf-based fuzzy finder shortcuts
# https://github.com/yuuu/shirube

# bash-it metadata
if type cite &>/dev/null; then
	cite about-plugin
	about-plugin 'fzf-based fuzzy finder shortcuts (ghq, worktree, branch, pr, history)'
fi

# Source the main implementation
SHIRUBE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SHIRUBE_DIR}/shirube.bash"
