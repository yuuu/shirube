#!/usr/bin/env bash
# Common test helpers: mock infrastructure and shirube.sh loader.

# Call this in each bats setup(). Creates a temp mock bin dir and prepends it to PATH.
# Also creates a fzf mock (always required for shirube.sh's top-level dependency check).
setup_mocks() {
  MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"
  # Use a minimal PATH so that tools like ghq/gh/git are "not found" unless
  # explicitly mocked in MOCK_BIN. /usr/bin and /bin provide sed, awk, grep etc.
  export PATH="$MOCK_BIN:/usr/bin:/bin"

  # fzf mock: reads stdin to /dev/null, prints MOCK_FZF_OUTPUT.
  # Returns exit 1 when MOCK_FZF_OUTPUT is empty, mimicking a cancelled fzf selection.
  cat > "$MOCK_BIN/fzf" << 'EOF'
#!/usr/bin/env bash
cat > /dev/null
[[ -z "$MOCK_FZF_OUTPUT" ]] && exit 1
printf '%s' "$MOCK_FZF_OUTPUT"
EOF
  chmod +x "$MOCK_BIN/fzf"
}

# Run a command with PATH restricted to MOCK_BIN only (no /usr/bin).
# Use for "tool not installed" tests where the tool exists at /usr/bin on the host.
# Must be called AFTER setup_mocks and after creating any required mocks.
run_minimal_path() {
  local saved_path="$PATH"
  export PATH="$MOCK_BIN"
  run "$@"
  export PATH="$saved_path"
}

# Set what the fzf mock will output.
# For functions using --print-query --expect, pass a 3-line string: $'query\nkey\nselection'
set_fzf_output() {
  export MOCK_FZF_OUTPUT="$1"
}

# Create a mock command that prints fixed stdout lines.
# Usage: create_mock <cmd> <output>
create_mock() {
  local cmd="$1" output="$2"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$output" > "$MOCK_BIN/$cmd"
  chmod +x "$MOCK_BIN/$cmd"
}

# Create a mock command that produces no output (used for presence-check-only tools).
create_empty_mock() {
  local cmd="$1"
  printf '#!/usr/bin/env bash\n' > "$MOCK_BIN/$cmd"
  chmod +x "$MOCK_BIN/$cmd"
}

# Source shirube.sh into the current shell, resetting the double-source guard first.
load_shirube() {
  unset SHIRUBE_LOADED
  # shellcheck source=../../shirube.sh
  # Shadow the `bind` built-in with a no-op so that `bind -x ...` in shirube.sh's
  # bash section does not fail in non-interactive test shells (readline not loaded).
  bind() { :; }
  source "$BATS_TEST_DIRNAME/../shirube.sh"
  unset -f bind
}
