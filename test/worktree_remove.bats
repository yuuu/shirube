#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

setup() {
  setup_mocks
  load_shirube
  WT_PATH="$BATS_TEST_TMPDIR/worktree"
  mkdir -p "$WT_PATH"
}

@test "__shirube_worktree_remove: removes worktree and branch on success" {
  cat > "$MOCK_BIN/git" << 'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$MOCK_BIN/git"

  run __shirube_worktree_remove "$WT_PATH" "feature/foo"
  assert_success
}

@test "__shirube_worktree_remove: falls back to rm -rf and prune when submodule error" {
  cat > "$MOCK_BIN/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "worktree" && "$2" == "remove" ]]; then
  echo "fatal: working trees containing submodules cannot be moved or removed" >&2
  exit 128
fi
exit 0
EOF
  chmod +x "$MOCK_BIN/git"

  run __shirube_worktree_remove "$WT_PATH" "feature/foo"
  assert_success
  assert [ ! -d "$WT_PATH" ]
}

@test "__shirube_worktree_remove: fails and prints error for non-submodule git error" {
  cat > "$MOCK_BIN/git" << 'EOF'
#!/usr/bin/env bash
if [[ "$1" == "worktree" && "$2" == "remove" ]]; then
  echo "fatal: '$3' is not a working tree" >&2
  exit 128
fi
exit 0
EOF
  chmod +x "$MOCK_BIN/git"

  run __shirube_worktree_remove "/nonexistent" "feature/foo"
  assert_failure
  assert_output --partial "is not a working tree"
}
