# SHIRUBE - fzf-based fuzzy finder shortcuts for bash and zsh

# Double-source guard
[[ -n "${SHIRUBE_LOADED:-}" ]] && return 0
SHIRUBE_LOADED=1

# Dependency check: fzf is required
if ! command -v fzf &>/dev/null; then
  echo "shirube: fzf is required but not found. Please install fzf." >&2
  return 1 2>/dev/null || exit 1
fi

# ==========================================================
# Common selection functions
# ==========================================================

# Select a ghq-managed repository via fzf.
# Prints the selected full path to stdout.
__shirube_select_ghq() {
  if ! command -v ghq &>/dev/null; then
    echo "shirube: ghq is not installed" >&2
    return 1
  fi

  ghq list --full-path | fzf --reverse --prompt='ghq> '
}

# Select a git worktree via fzf.
# Prints the selected worktree directory path to stdout.
__shirube_select_worktree() {
  if ! command -v git &>/dev/null; then
    echo "shirube: git is not installed" >&2
    return 1
  fi

  local line
  line="$(git worktree list 2>/dev/null | fzf --reverse --prompt='worktree> ')"
  [[ -n "$line" ]] && echo "$line" | awk '{print $1}'
}

# Select a git branch via fzf.
# Prints the selected branch name to stdout.
__shirube_select_branch() {
  if ! command -v git &>/dev/null; then
    echo "shirube: git is not installed" >&2
    return 1
  fi

  git branch --all 2>/dev/null \
    | grep -v 'HEAD' \
    | fzf --reverse --prompt='branch> ' \
    | sed 's/^[* ]*//' \
    | sed 's|^remotes/[^/]*/||'
}

# Select a GitHub PR via fzf.
# Prints the selected PR number to stdout.
__shirube_select_pr() {
  if ! command -v gh &>/dev/null; then
    echo "shirube: gh (GitHub CLI) is not installed" >&2
    return 1
  fi

  local line
  line="$(gh pr list 2>/dev/null | fzf --reverse --prompt='pr> ')"
  [[ -n "$line" ]] && echo "$line" | awk '{print $1}'
}

# ==========================================================
# Shell-specific integration
# ==========================================================

if [[ -n "$ZSH_VERSION" ]]; then
  # --------------------------------------------------------
  # zsh: widgets + bindkey
  # --------------------------------------------------------

  shirube-ghq-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local dir
    dir="$(__shirube_select_ghq)"
    if [[ -z "$dir" ]]; then
      zle redisplay
      return 0
    fi
    zle push-line
    BUFFER="builtin cd -- ${(q)dir}"
    zle accept-line
  }
  zle -N shirube-ghq-widget
  bindkey '^x^g' shirube-ghq-widget

  shirube-worktree-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local dir
    dir="$(__shirube_select_worktree)"
    if [[ -z "$dir" ]]; then
      zle redisplay
      return 0
    fi
    zle push-line
    BUFFER="builtin cd -- ${(q)dir}"
    zle accept-line
  }
  zle -N shirube-worktree-widget
  bindkey '^x^w' shirube-worktree-widget

  shirube-branch-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local branch
    branch="$(__shirube_select_branch)"
    if [[ -z "$branch" ]]; then
      zle redisplay
      return 0
    fi
    zle push-line
    BUFFER="git checkout ${(q)branch}"
    zle accept-line
  }
  zle -N shirube-branch-widget
  bindkey '^x^b' shirube-branch-widget

  shirube-pr-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local pr_number
    pr_number="$(__shirube_select_pr)"
    if [[ -z "$pr_number" ]]; then
      zle redisplay
      return 0
    fi
    zle push-line
    BUFFER="gh pr checkout ${pr_number}"
    zle accept-line
  }
  zle -N shirube-pr-widget
  bindkey '^x^p' shirube-pr-widget

  shirube-history-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local selected
    selected="$(fc -rl 1 \
      | awk '{ cmd=$0; sub(/^[ ]*[0-9]+\*?[ ]+/, "", cmd); if (!seen[cmd]++) print cmd }' \
      | fzf --reverse --prompt='history> ' --query="$LBUFFER")"
    if [[ -z "$selected" ]]; then
      zle redisplay
      return 0
    fi
    LBUFFER="$selected"
    RBUFFER=""
    zle reset-prompt
  }
  zle -N shirube-history-widget
  bindkey '^r' shirube-history-widget

elif [[ -n "$BASH_VERSION" ]]; then
  # --------------------------------------------------------
  # bash: bind -x (bash 4+ required)
  # --------------------------------------------------------

  __shirube_ghq() {
    local dir
    dir="$(__shirube_select_ghq)"
    if [[ -n "$dir" ]]; then
      builtin cd -- "$dir" || return 1
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_worktree() {
    local dir
    dir="$(__shirube_select_worktree)"
    if [[ -n "$dir" ]]; then
      builtin cd -- "$dir" || return 1
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_branch() {
    local branch
    branch="$(__shirube_select_branch)"
    if [[ -n "$branch" ]]; then
      git checkout "$branch"
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_pr() {
    local pr_number
    pr_number="$(__shirube_select_pr)"
    if [[ -n "$pr_number" ]]; then
      gh pr checkout "$pr_number"
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_history() {
    local selected
    selected="$(builtin fc -lnr -2147483648 \
      | awk '!seen[$0]++' \
      | fzf --reverse --prompt='history> ' --query="$READLINE_LINE")"
    if [[ -n "$selected" ]]; then
      READLINE_LINE="$selected"
      READLINE_POINT=${#READLINE_LINE}
    else
      READLINE_LINE=""
      READLINE_POINT=0
    fi
  }

  bind -x '"\C-x\C-g": __shirube_ghq'
  bind -x '"\C-x\C-w": __shirube_worktree'
  bind -x '"\C-x\C-b": __shirube_branch'
  bind -x '"\C-x\C-p": __shirube_pr'
  bind -x '"\C-r": __shirube_history'
fi
