# shirube module: backlog (Ctrl+x a)
# Select a Backlog issue via bee and open it in the browser.

# Select a Backlog issue via fzf.
# Prints the selected issue key to stdout.
__shirube_select_backlog() {
  if ! command -v bee &>/dev/null; then
    echo "shirube: bee (Backlog CLI) is not installed" >&2
    return 1
  fi

  # bee prints a header line first. Without -p it lists issues across the
  # space unless BACKLOG_PROJECT is set.
  local line
  line="$(bee issue list --count 100 2>/dev/null \
    | fzf --reverse --prompt='backlog> ' --header-lines=1 \
          --preview 'bee issue view {1}')"
  [[ -z "$line" ]] && return 1

  echo "$line" | awk '{print $1}'
}

# Print the command line that opens the selected issue in the browser.
__shirube_backlog_command() {
  local issue_key
  issue_key="$(__shirube_select_backlog)"
  [[ -z "$issue_key" ]] && return 1
  printf 'bee issue view --web %q' "$issue_key"
}

# Like the issue module, opening a browser runs in place.
__shirube_register backlog '^xa' run
