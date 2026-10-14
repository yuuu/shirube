# shirube module: history (Ctrl+r)
# Select a command from history and put it on the command line.

# Print the selected history entry, using $1 (the current line) as the query.
__shirube_history_command() {
  local query="$1"
  if [[ -n "$ZSH_VERSION" ]]; then
    fc -rl 1 \
      | awk '{ cmd=$0; sub(/^[ ]*[0-9]+\*?[ ]+/, "", cmd); if (!seen[cmd]++) print cmd }'
  else
    builtin fc -lnr -2147483648 | awk '!seen[$0]++'
  fi | fzf --reverse --prompt='history> ' --query="$query"
}

__shirube_register history '^r' insert
