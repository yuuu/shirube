# shirube module: ghq (Ctrl+x g)
# Select a ghq-managed Git repository and jump to it.

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

# Print the command line that jumps to the selected repository.
__shirube_ghq_command() {
  local dir
  dir="$(__shirube_select_ghq)"
  [[ -z "$dir" ]] && return 1
  printf 'builtin cd -- %q' "$dir"
}

__shirube_register ghq '^xg' submit
