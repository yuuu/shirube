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

  ghq list --full-path | fzf --reverse --prompt='ghq> ' \
    --preview 'ls -p {}'
}

# Select a git worktree via fzf (supports ctrl-n/ctrl-r).
# Output: line 1 = "select", "new", or "delete", line 2 = branch name.
__shirube_select_worktree() {
  if ! command -v git &>/dev/null; then
    echo "shirube: git is not installed" >&2
    return 1
  fi

  local result query key selection
  result="$(command git worktree list 2>/dev/null \
    | fzf --reverse --prompt='worktree> ' \
          --header='ctrl-n: new / ctrl-r: delete' \
          --preview 'git -C {1} log --oneline -20' \
          --print-query --expect=ctrl-n,ctrl-r \
          --bind ctrl-r:accept)"
  [[ -z "$result" ]] && return 1

  query="$(sed -n '1p' <<< "$result")"
  key="$(sed -n '2p' <<< "$result")"
  selection="$(sed -n '3p' <<< "$result")"

  if [[ "$key" == "ctrl-n" && -n "$query" ]]; then
    printf 'new\n%s' "$query"
  elif [[ "$key" == "ctrl-r" && -n "$selection" ]]; then
    local branch wt_path
    wt_path="$(awk '{print $1}' <<< "$selection")"
    branch="$(grep -o '\[.*\]' <<< "$selection" | tr -d '[]')"
    [[ -n "$branch" ]] && printf 'delete\n%s\n%s' "$branch" "$wt_path"
  elif [[ -n "$selection" ]]; then
    local branch wt_path
    wt_path="$(awk '{print $1}' <<< "$selection")"
    branch="$(grep -o '\[.*\]' <<< "$selection" | tr -d '[]')"
    [[ -n "$branch" ]] && printf 'select\n%s\n%s' "$branch" "$wt_path"
  fi
}

# Select a git branch via fzf (supports ctrl-n/ctrl-r).
# Output: line 1 = "select", "new", or "delete", line 2 = branch name.
__shirube_select_branch() {
  if ! command -v git &>/dev/null; then
    echo "shirube: git is not installed" >&2
    return 1
  fi

  local result query key selection
  result="$(git branch --all 2>/dev/null \
    | grep -v 'HEAD' \
    | fzf --reverse --prompt='branch> ' \
          --header='ctrl-n: new / ctrl-r: delete' \
          --preview 'git log --oneline --graph -20 $(echo {} | sed "s/^[* ]*//" | sed "s|^remotes/[^/]*/||")' \
          --print-query --expect=ctrl-n,ctrl-r \
          --bind ctrl-r:accept)"
  [[ -z "$result" ]] && return 1

  query="$(sed -n '1p' <<< "$result")"
  key="$(sed -n '2p' <<< "$result")"
  selection="$(sed -n '3p' <<< "$result")"

  if [[ "$key" == "ctrl-n" && -n "$query" ]]; then
    printf 'new\n%s' "$query"
  elif [[ "$key" == "ctrl-r" && -n "$selection" ]]; then
    local branch
    branch="$(echo "$selection" | sed 's/^[* ]*//' | sed 's|^remotes/[^/]*/||')"
    [[ -n "$branch" ]] && printf 'delete\n%s' "$branch"
  elif [[ -n "$selection" ]]; then
    local branch
    branch="$(echo "$selection" | sed 's/^[* ]*//' | sed 's|^remotes/[^/]*/||')"
    [[ -n "$branch" ]] && printf 'select\n%s' "$branch"
  fi
}

# Select a GitHub PR via fzf (supports ctrl-o to open in browser).
# Output: line 1 = "select" or "open", line 2 = PR number.
__shirube_select_pr() {
  if ! command -v gh &>/dev/null; then
    echo "shirube: gh (GitHub CLI) is not installed" >&2
    return 1
  fi

  local result key line pr_number
  result="$(gh pr list 2>/dev/null \
    | fzf --reverse --prompt='pr> ' \
          --header='ctrl-o: open in browser' \
          --preview 'gh pr view {1}' \
          --print-query --expect=ctrl-o)"
  [[ -z "$result" ]] && return 1

  key="$(sed -n '2p' <<< "$result")"
  line="$(sed -n '3p' <<< "$result")"
  [[ -z "$line" ]] && return 1

  pr_number="$(echo "$line" | awk '{print $1}')"
  if [[ "$key" == "ctrl-o" ]]; then
    printf 'open\n%s' "$pr_number"
  else
    printf 'select\n%s' "$pr_number"
  fi
}

# Select a GitHub Issue via fzf.
# Prints the selected issue number to stdout.
__shirube_select_issue() {
  if ! command -v gh &>/dev/null; then
    echo "shirube: gh (GitHub CLI) is not installed" >&2
    return 1
  fi

  local line
  line="$(gh issue list 2>/dev/null \
    | fzf --reverse --prompt='issue> ' \
          --preview 'gh issue view {1}')"
  [[ -z "$line" ]] && return 1

  echo "$line" | awk '{print $1}'
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
  bindkey '^xg' shirube-ghq-widget

  shirube-worktree-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local result action branch wt_path
    result="$(__shirube_select_worktree)"
    if [[ -z "$result" ]]; then
      zle redisplay
      return 0
    fi
    action="$(sed -n '1p' <<< "$result")"
    branch="$(sed -n '2p' <<< "$result")"
    wt_path="$(sed -n '3p' <<< "$result")"
    zle push-line
    if [[ "$action" == "select" ]]; then
      BUFFER="builtin cd -- ${(q)wt_path}"
    elif [[ "$action" == "new" ]]; then
      local main_root new_path
      main_root="$(command git worktree list | awk 'NR==1 {print $1}')"
      new_path="${main_root}/.worktrees/${branch}"
      BUFFER="git worktree add ${(q)new_path} -b ${(q)branch} && builtin cd -- ${(q)new_path}"
    elif [[ "$action" == "delete" ]]; then
      BUFFER="git worktree remove ${(q)wt_path} && git branch -d ${(q)branch}"
    fi
    zle accept-line
  }
  zle -N shirube-worktree-widget
  bindkey '^xw' shirube-worktree-widget

  shirube-branch-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local result action branch
    result="$(__shirube_select_branch)"
    if [[ -z "$result" ]]; then
      zle redisplay
      return 0
    fi
    action="$(sed -n '1p' <<< "$result")"
    branch="$(sed -n '2p' <<< "$result")"
    zle push-line
    if [[ "$action" == "new" ]]; then
      BUFFER="git checkout -b ${(q)branch}"
    elif [[ "$action" == "delete" ]]; then
      BUFFER="git branch -d ${(q)branch}"
    else
      BUFFER="git checkout ${(q)branch}"
    fi
    zle accept-line
  }
  zle -N shirube-branch-widget
  bindkey '^xb' shirube-branch-widget

  shirube-pr-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local result action pr_number
    result="$(__shirube_select_pr)"
    if [[ -z "$result" ]]; then
      zle redisplay
      return 0
    fi
    action="$(sed -n '1p' <<< "$result")"
    pr_number="$(sed -n '2p' <<< "$result")"
    zle push-line
    if [[ "$action" == "open" ]]; then
      BUFFER="gh pr view --web ${pr_number}"
    else
      BUFFER="gh pr checkout ${pr_number}"
    fi
    zle accept-line
  }
  zle -N shirube-pr-widget
  bindkey '^xp' shirube-pr-widget

  shirube-issue-widget() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local issue_number
    issue_number="$(__shirube_select_issue)"
    if [[ -z "$issue_number" ]]; then
      zle redisplay
      return 0
    fi
    zle push-line
    BUFFER="gh issue view --web ${issue_number}"
    zle accept-line
  }
  zle -N shirube-issue-widget
  bindkey '^xi' shirube-issue-widget

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
    local result action branch path
    result="$(__shirube_select_worktree)"
    if [[ -n "$result" ]]; then
      action="$(sed -n '1p' <<< "$result")"
      branch="$(sed -n '2p' <<< "$result")"
      path="$(sed -n '3p' <<< "$result")"
      if [[ "$action" == "select" ]]; then
        builtin cd -- "$path" || return
      elif [[ "$action" == "new" ]]; then
        local main_root new_path
        main_root="$(git worktree list | awk 'NR==1 {print $1}')"
        new_path="${main_root}/.worktrees/${branch}"
        git worktree add "$new_path" -b "$branch" && { builtin cd -- "$new_path" || return; }
      elif [[ "$action" == "delete" ]]; then
        git worktree remove "$path" && git branch -d "$branch"
      fi
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_branch() {
    local result action branch
    result="$(__shirube_select_branch)"
    if [[ -n "$result" ]]; then
      action="$(sed -n '1p' <<< "$result")"
      branch="$(sed -n '2p' <<< "$result")"
      if [[ "$action" == "new" ]]; then
        git checkout -b "$branch"
      elif [[ "$action" == "delete" ]]; then
        git branch -d "$branch"
      else
        git checkout "$branch"
      fi
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_pr() {
    local result action pr_number
    result="$(__shirube_select_pr)"
    if [[ -n "$result" ]]; then
      action="$(sed -n '1p' <<< "$result")"
      pr_number="$(sed -n '2p' <<< "$result")"
      if [[ "$action" == "open" ]]; then
        gh pr view --web "$pr_number"
      else
        gh pr checkout "$pr_number"
      fi
    fi
    READLINE_LINE=""
    READLINE_POINT=0
  }

  __shirube_issue() {
    local issue_number
    issue_number="$(__shirube_select_issue)"
    if [[ -n "$issue_number" ]]; then
      gh issue view --web "$issue_number"
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

  bind -x '"\C-xg": __shirube_ghq'
  bind -x '"\C-xw": __shirube_worktree'
  bind -x '"\C-xb": __shirube_branch'
  bind -x '"\C-xp": __shirube_pr'
  bind -x '"\C-xi": __shirube_issue'
  bind -x '"\C-r": __shirube_history'
fi
