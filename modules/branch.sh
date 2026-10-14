# shirube module: branch (Ctrl+x b)
# Select a git branch and check it out (ctrl-n: new / ctrl-r: delete).

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

# Print the command line that checks out, creates, or deletes the selected branch.
__shirube_branch_command() {
  local result action branch
  result="$(__shirube_select_branch)"
  [[ -z "$result" ]] && return 1
  action="$(sed -n '1p' <<< "$result")"
  branch="$(sed -n '2p' <<< "$result")"
  if [[ "$action" == "new" ]]; then
    printf 'git checkout -b %q' "$branch"
  elif [[ "$action" == "delete" ]]; then
    printf 'git branch -d %q' "$branch"
  else
    printf 'git checkout %q' "$branch"
  fi
}

__shirube_register branch '^xb' submit
