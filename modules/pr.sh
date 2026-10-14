# shirube module: pr (Ctrl+x p)
# Select a pull request and check it out (ctrl-o: open in browser).

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

# Print the command line that checks out or opens the selected PR.
__shirube_pr_command() {
  local result action pr_number
  result="$(__shirube_select_pr)"
  [[ -z "$result" ]] && return 1
  action="$(sed -n '1p' <<< "$result")"
  pr_number="$(sed -n '2p' <<< "$result")"
  if [[ "$action" == "open" ]]; then
    printf 'gh pr view --web %q' "$pr_number"
  else
    printf 'gh pr checkout %q' "$pr_number"
  fi
}

__shirube_register pr '^xp' submit
