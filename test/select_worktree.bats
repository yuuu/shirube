#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

# git worktree list output format: /path/to/repo  abc1234  [main]

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_select_worktree: exits 1 with error when git is not installed" {
  create_empty_mock "git-wt"
  set_fzf_output ""

  # /usr/bin/git exists on macOS (Xcode CLT stub), so restrict PATH to MOCK_BIN only.
  run_minimal_path __shirube_select_worktree
  assert_failure
  assert_output --partial "git is not installed"
}

@test "__shirube_select_worktree: exits 1 when fzf is cancelled" {
  create_empty_mock "git"
  set_fzf_output $'\n\n'

  run __shirube_select_worktree
  assert_failure
}

@test "__shirube_select_worktree: prints 'select', branch name, and path when worktree is selected" {
  create_empty_mock "git"
  set_fzf_output $'\n\n/path/to/repo  abc1234  [main]'

  run __shirube_select_worktree
  assert_success
  assert_output "$(printf 'select\nmain\n/path/to/repo')"
}

@test "__shirube_select_worktree: prints 'new' and query string on ctrl-n" {
  create_empty_mock "git"
  set_fzf_output $'new-feature\nctrl-n\n'

  run __shirube_select_worktree
  assert_success
  assert_output "$(printf 'new\nnew-feature')"
}

@test "__shirube_select_worktree: prints 'delete', branch name, and path on ctrl-r" {
  create_empty_mock "git"
  set_fzf_output $'\nctrl-r\n/path/to/repo  abc1234  [feature/foo]'

  run __shirube_select_worktree
  assert_success
  assert_output "$(printf 'delete\nfeature/foo\n/path/to/repo')"
}
