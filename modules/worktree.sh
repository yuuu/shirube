# shirube module: worktree (Ctrl+x w)
# Select a git worktree and jump to it (ctrl-n: new / ctrl-r: delete).

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

# Remove a git worktree, falling back to rm -rf + prune for worktrees containing submodules.
__shirube_worktree_remove() {
  local wt_path="$1" branch="$2"
  local err rc
  err="$(git worktree remove "$wt_path" 2>&1)"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    if [[ "$err" == *"submodule"* ]]; then
      rm -rf "$wt_path" && git worktree prune
    else
      echo "$err" >&2
      return 1
    fi
  fi
  git branch -d "$branch"
}

# Copy files listed in .worktreeinclude from main_root to new_path.
# Lines starting with # and empty lines are skipped.
# Trailing slashes (directory markers) are stripped before matching.
__shirube_worktree_copy_includes() {
  local main_root="$1" new_path="$2"
  local include_file="${main_root}/.worktreeinclude"
  [[ -f "$include_file" ]] || return 0
  local pattern
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    [[ -z "$pattern" || "$pattern" == "#"* ]] && continue
    local stripped="${pattern%/}"
    local src="${main_root}/${stripped}"
    [[ -e "$src" ]] || continue
    local dst="${new_path}/${stripped}"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src" "$dst"
  done < "$include_file"
}

# Print the command line that jumps to, creates, or deletes the selected worktree.
__shirube_worktree_command() {
  local result action branch wt_path
  result="$(__shirube_select_worktree)"
  [[ -z "$result" ]] && return 1
  action="$(sed -n '1p' <<< "$result")"
  branch="$(sed -n '2p' <<< "$result")"
  wt_path="$(sed -n '3p' <<< "$result")"
  if [[ "$action" == "select" ]]; then
    printf 'builtin cd -- %q' "$wt_path"
  elif [[ "$action" == "new" ]]; then
    local main_root new_path
    main_root="$(command git worktree list | awk 'NR==1 {print $1}')"
    new_path="${main_root}/.worktrees/${branch}"
    printf 'git worktree add %q -b %q && builtin cd -- %q && __shirube_worktree_copy_includes %q %q' \
      "$new_path" "$branch" "$new_path" "$main_root" "$new_path"
  elif [[ "$action" == "delete" ]]; then
    printf '__shirube_worktree_remove %q %q' "$wt_path" "$branch"
  else
    return 1
  fi
}

__shirube_register worktree '^xw' submit
