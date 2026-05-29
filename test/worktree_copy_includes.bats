#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

setup() {
  setup_mocks
  load_shirube
  MAIN_ROOT="$BATS_TEST_TMPDIR/main"
  NEW_PATH="$BATS_TEST_TMPDIR/worktree"
  mkdir -p "$MAIN_ROOT" "$NEW_PATH"
}

@test "__shirube_worktree_copy_includes: does nothing when .worktreeinclude does not exist" {
  run __shirube_worktree_copy_includes "$MAIN_ROOT" "$NEW_PATH"
  assert_success
}

@test "__shirube_worktree_copy_includes: copies a file listed in .worktreeinclude" {
  printf '.env.local\n' > "$MAIN_ROOT/.worktreeinclude"
  printf 'SECRET=value\n' > "$MAIN_ROOT/.env.local"

  run __shirube_worktree_copy_includes "$MAIN_ROOT" "$NEW_PATH"
  assert_success
  assert [ -f "$NEW_PATH/.env.local" ]
}

@test "__shirube_worktree_copy_includes: copies a directory listed with trailing slash" {
  printf '.vscode/\n' > "$MAIN_ROOT/.worktreeinclude"
  mkdir -p "$MAIN_ROOT/.vscode"
  printf '{}\n' > "$MAIN_ROOT/.vscode/settings.json"

  run __shirube_worktree_copy_includes "$MAIN_ROOT" "$NEW_PATH"
  assert_success
  assert [ -d "$NEW_PATH/.vscode" ]
  assert [ -f "$NEW_PATH/.vscode/settings.json" ]
}

@test "__shirube_worktree_copy_includes: skips patterns that do not match any file" {
  printf 'nonexistent.file\n' > "$MAIN_ROOT/.worktreeinclude"

  run __shirube_worktree_copy_includes "$MAIN_ROOT" "$NEW_PATH"
  assert_success
}

@test "__shirube_worktree_copy_includes: skips comment lines and empty lines" {
  printf '# comment\n\n.env.local\n' > "$MAIN_ROOT/.worktreeinclude"
  printf 'SECRET=value\n' > "$MAIN_ROOT/.env.local"

  run __shirube_worktree_copy_includes "$MAIN_ROOT" "$NEW_PATH"
  assert_success
  assert [ -f "$NEW_PATH/.env.local" ]
}

@test "__shirube_worktree_copy_includes: copies multiple files" {
  printf '.env.local\nCLAUDE.local.md\n' > "$MAIN_ROOT/.worktreeinclude"
  printf 'SECRET=value\n' > "$MAIN_ROOT/.env.local"
  printf '# local notes\n' > "$MAIN_ROOT/CLAUDE.local.md"

  run __shirube_worktree_copy_includes "$MAIN_ROOT" "$NEW_PATH"
  assert_success
  assert [ -f "$NEW_PATH/.env.local" ]
  assert [ -f "$NEW_PATH/CLAUDE.local.md" ]
}
