# shirube module: issue (Ctrl+x i)
# Select an issue and open it in the browser.

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

# Print the command line that opens the selected issue in the browser.
__shirube_issue_command() {
  local issue_number
  issue_number="$(__shirube_select_issue)"
  [[ -z "$issue_number" ]] && return 1
  printf 'gh issue view --web %q' "$issue_number"
}

# Opening a browser doesn't change anything the prompt reflects, so this
# runs in place instead of being submitted as a command line.
__shirube_register issue '^xi' run
