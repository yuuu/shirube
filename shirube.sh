# SHIRUBE - fzf-based fuzzy finder shortcuts for bash and zsh

# Double-source guard
[[ -n "${SHIRUBE_LOADED:-}" ]] && return 0
SHIRUBE_LOADED=1

# Dependency check: fzf is required
if ! command -v fzf &>/dev/null; then
  echo "shirube: fzf is required but not found. Please install fzf." >&2
  return 1 2>/dev/null || exit 1
fi

# Directory of this file, where modules/ is looked up
if [[ -n "$ZSH_VERSION" ]]; then
  SHIRUBE_DIR="${(%):-%x}"
else
  SHIRUBE_DIR="${BASH_SOURCE[0]}"
fi
SHIRUBE_DIR="$(cd "$(dirname "$SHIRUBE_DIR")" && pwd)"

# ==========================================================
# Modules and configuration
# ==========================================================

# Built-in modules, in the order they are loaded and listed in the Ctrl+x
# hint. Each one lives in modules/<name>.sh.
__shirube_modules=(ghq worktree branch pr issue backlog history)

# Names of the disabled modules, as " name name ". backlog starts off since
# it shares Ctrl+x i with issue; the config file can turn it on.
__shirube_disabled=" backlog "

# Read the config file: one "<module> = on|off" per line, # starts a comment.
# Modules not mentioned keep their default.
__shirube_load_config() {
  local file="$1" line key value lineno=0
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    line="${line%%"#"*}"
    [[ "$line" == *[![:space:]]* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    key="${key//[[:space:]]/}"
    value="${value//[[:space:]]/}"
    if [[ "$line" != *=* || " ${__shirube_modules[*]} " != *" $key "* ]]; then
      echo "shirube: ${file}:${lineno}: unknown setting '${key}'" >&2
      continue
    fi
    case "$value" in
      on | true | yes | 1) __shirube_disabled="${__shirube_disabled// $key / }" ;;
      off | false | no | 0) __shirube_disabled="${__shirube_disabled// $key / } $key " ;;
      *) echo "shirube: ${file}:${lineno}: invalid value '${value}' for ${key} (use on or off)" >&2 ;;
    esac
  done < "$file"
}

# Succeed if the given module is enabled.
__shirube_enabled() {
  [[ "$__shirube_disabled" != *" $1 "* ]]
}

# Keys listed in the hint shown when Ctrl+x is pressed and the next key has
# not been typed yet, as "<key>:<description>". Filled by __shirube_register.
__shirube_prefix_keys=()

# Called by each module to bind its key. The module provides
# __shirube_<name>_command, which runs the selection and prints the result
# (exit status non-zero when cancelled). <key> is in bindkey notation
# ("^xg", "^r") and <mode> decides what happens to the printed result:
#   submit  run it as a command line, as if typed and Enter pressed, so that
#           prompts reflecting $PWD or the branch are regenerated
#   run     run it in place without submitting (bash; same as submit in zsh)
#   insert  put it on the command line for the user to review or edit;
#           the current line is passed as $1
__shirube_register() {
  local name="$1" key="$2" mode="$3" item
  local -a kept=()
  if [[ "$key" == "^x"? ]]; then
    # A module loaded later takes over the key, also in the hint
    for item in "${__shirube_prefix_keys[@]}"; do
      [[ "$item" == "${key#"^x"}:"* ]] || kept+=("$item")
    done
    __shirube_prefix_keys=("${kept[@]}" "${key#"^x"}:${name}")
  fi
  __shirube_bind "$name" "$key" "$mode"
}

# ==========================================================
# Shell-specific integration
# ==========================================================

if [[ -n "$ZSH_VERSION" ]]; then
  # --------------------------------------------------------
  # zsh: widgets + bindkey
  # --------------------------------------------------------

  # Each module gets a widget named shirube-<name>-widget, whose function
  # calls the one below for its mode with the module name. The name is passed
  # explicitly because $WIDGET is not updated when a widget is run through
  # `zle <widget>` from another one, as shirube-prefix-widget does.
  __shirube_widget_submit() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local cmd
    cmd="$("__shirube_$1_command")"
    if [[ -z "$cmd" ]]; then
      zle redisplay
      return 0
    fi
    zle push-line
    BUFFER="$cmd"
    zle accept-line
  }

  __shirube_widget_insert() {
    setopt localoptions pipefail no_aliases 2>/dev/null
    local selected
    selected="$("__shirube_$1_command" "$LBUFFER")"
    if [[ -z "$selected" ]]; then
      zle redisplay
      return 0
    fi
    LBUFFER="$selected"
    RBUFFER=""
    zle reset-prompt
  }

  __shirube_bind() {
    local name="$1" key="$2" mode="$3" widget="shirube-$1-widget"
    [[ "$mode" == run ]] && mode=submit
    # shellcheck disable=SC2004 # functions is a zsh associative array
    functions[$widget]="__shirube_widget_${mode} ${name}"
    zle -N "$widget"
    bindkey "$key" "$widget"
  }

  # Ctrl+x alone: when the next key does not follow within KEYTIMEOUT, show a
  # hint below the command line, then run whatever Ctrl+x <key> is bound to.
  # The hint is drawn through POSTDISPLAY and region_highlight (offsets count
  # from the start of BUFFER) so that it can be colored, unlike `zle -R`.
  shirube-prefix-widget() {
    local key seq binding item k hint start
    local saved_postdisplay="$POSTDISPLAY"
    local -a saved_highlight=("${region_highlight[@]}")
    hint=$'\n C-x '
    region_highlight+=("$((${#BUFFER} + 1)) $((${#BUFFER} + ${#hint})) fg=black,bg=cyan,bold")
    for item in "${__shirube_prefix_keys[@]}"; do
      k="${item%%:*}"
      start=$((${#BUFFER} + ${#hint} + 2))
      hint+="  $k ${item#*:}"
      region_highlight+=("$start $((start + ${#k})) fg=yellow,bold")
    done
    start=$((${#BUFFER} + ${#hint} + 2))
    hint+="  Esc cancel"
    region_highlight+=("$start $((${#BUFFER} + ${#hint})) fg=8")
    POSTDISPLAY="$hint"
    zle -R
    read -r -k 1 key
    POSTDISPLAY="$saved_postdisplay"
    region_highlight=("${saved_highlight[@]}")
    zle -R
    [[ -z "$key" || "$key" == $'\e' ]] && return 0
    case "$key" in
      '^') seq='\^' ;;
      "\\") seq="\\\\" ;;
      *) seq="${(V)key}" ;;
    esac
    binding="$(bindkey -M "$KEYMAP" -- "^X${seq}")"
    binding="${binding##* }"
    if [[ -n "$binding" && "$binding" != '"'* && "$binding" != undefined-key ]]; then
      zle "$binding"
    fi
  }

  __shirube_bind_prefix() {
    zle -N shirube-prefix-widget
    bindkey '^x' shirube-prefix-widget
  }

elif [[ -n "$BASH_VERSION" ]]; then
  # --------------------------------------------------------
  # bash: bind -x (bash 4+ required)
  # --------------------------------------------------------

  # Modules in "submit" mode are run by typing `__shirube_run <name>` into
  # the line and pressing Enter for real (see __shirube_bind), so the
  # cd/checkout happens as a normal top-level command and the next prompt is
  # regenerated (git/dir-aware prompts like starship pick up the new
  # $PWD/branch immediately). Running them via `bind -x` instead only
  # redraws the *current* prompt line in place, so the change wouldn't be
  # reflected until another Enter was pressed.
  __shirube_run() {
    local cmd
    cmd="$("__shirube_$1_command")" || return 0
    [[ -n "$cmd" ]] && eval "$cmd"
  }

  # "run" mode, via bind -x: run the command in place and clear the line.
  __shirube_run_in_place() {
    __shirube_run "$1"
    READLINE_LINE=""
    READLINE_POINT=0
  }

  # "insert" mode, via bind -x: replace the line with the selection.
  __shirube_insert() {
    READLINE_LINE="$("__shirube_$1_command" "$READLINE_LINE")"
    READLINE_POINT=${#READLINE_LINE}
  }

  __shirube_bind() {
    local name="$1" key="${2//^/\\C-}" mode="$3"
    case "$mode" in
      # \C-u (unix-line-discard) clears whatever was on the line first,
      # unlike \C-a\C-k which relies on emacs-only bindings; it also works
      # under `set -o vi`. \C-m (Enter) then submits the typed command.
      submit) bind "\"${key}\": \"\\C-u__shirube_run ${name}\\C-m\"" ;;
      run) bind -x "\"${key}\": __shirube_run_in_place ${name}" ;;
      insert) bind -x "\"${key}\": __shirube_insert ${name}" ;;
    esac
  }

  # Look up what "\C-x<key>" is bound to and print it as a readline binding:
  # "-x <command>" for bind -x, otherwise a function name or quoted macro.
  __shirube_prefix_lookup() {
    local key="$1" seq n line opt prefix
    local ctrl='abcdefghijklmnopqrstuvwxyz'
    printf -v n '%d' "'$key"
    if ((n >= 1 && n <= 26)); then
      seq="\\C-${ctrl:n-1:1}"
    elif ((n == 127)); then
      seq='\C-?'
    elif [[ "$key" == '"' || "$key" == "\\" ]]; then
      seq="\\$key"
    else
      seq="$key"
    fi
    prefix="\"\\C-x${seq}\""
    for opt in -X -s -p; do
      while IFS= read -r line; do
        if [[ "$line" == "$prefix"[:\ ]* ]]; then
          line="${line:${#prefix}}"
          line="${line#:}"
          line="${line# }"
          if [[ "$opt" == -X ]]; then
            line="${line#\"}"
            printf -- '-x %s\n' "${line%\"}"
          else
            printf '%s\n' "$line"
          fi
          return 0
        fi
      done < <(bind "$opt")
    done
    return 1
  }

  # Print the colored hint for __shirube_prefix, dropping trailing entries
  # that would not fit in the terminal width so that it stays on one line.
  __shirube_prefix_hint() {
    local item key desc width=5 cols="${COLUMNS:-80}"
    printf '\e[1;30;46m C-x \e[m'
    for item in "${__shirube_prefix_keys[@]}" "Esc:cancel"; do
      key="${item%%:*}" desc="${item#*:}"
      width=$((width + 3 + ${#key} + ${#desc}))
      ((width >= cols)) && break
      if [[ "$key" == Esc ]]; then
        printf '  \e[90m%s %s\e[m' "$key" "$desc"
      else
        printf '  \e[1;33m%s\e[m %s' "$key" "$desc"
      fi
    done
  }

  # Ctrl+x alone: when the next key does not follow within keyseq-timeout,
  # show a hint in place of the command line, then run whatever Ctrl+x <key>
  # is bound to. Readline functions and macros are run through the
  # "\C-x\C-_a" key, which is rebound here and invoked right after this.
  __shirube_prefix() {
    local key binding
    # The hint fits on one line, so "\r\e[J" below erases all of it
    printf '\r\e[J%s' "$(__shirube_prefix_hint)" >/dev/tty
    IFS= read -rsn1 key </dev/tty
    printf '\r\e[J' >/dev/tty
    if [[ -n "$key" && "$key" != $'\e' ]]; then
      binding="$(__shirube_prefix_lookup "$key")"
    fi
    if [[ "$binding" == "-x "* ]]; then
      eval "${binding#-x }"
      binding=""
    fi
    bind "\"\\C-x\\C-_a\": ${binding:-\"\"}"
  }

  __shirube_bind_prefix() {
    bind -x '"\C-x\C-_s": __shirube_prefix'
    bind '"\C-x\C-_a": ""'
    bind '"\C-x": "\C-x\C-_s\C-x\C-_a"'
  }
fi

# ==========================================================
# Loading
# ==========================================================

__shirube_load_config "${SHIRUBE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/shirube/config}"

for __shirube_module in "${__shirube_modules[@]}"; do
  if __shirube_enabled "$__shirube_module"; then
    source "${SHIRUBE_DIR}/modules/${__shirube_module}.sh"
  fi
done
unset __shirube_module

# Leave Ctrl+x untouched when no enabled module uses it
if ((${#__shirube_prefix_keys[@]} > 0)); then
  __shirube_bind_prefix
fi
