#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

# git branch --all output format:
#   * main
#     feature/foo
#     remotes/origin/main

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_select_branch: exits 1 with error when git is not installed" {
  set_fzf_output ""

  # /usr/bin/git exists on macOS (Xcode CLT stub), so restrict PATH to MOCK_BIN only.
  run_minimal_path __shirube_select_branch
  assert_failure
  assert_output --partial "git is not installed"
}

@test "__shirube_select_branch: exits 1 when fzf is cancelled" {
  create_empty_mock "git"
  set_fzf_output $'\n\n'

  run __shirube_select_branch
  assert_failure
}

@test "__shirube_select_branch: prints 'select' and branch name for current branch (with * prefix)" {
  create_empty_mock "git"
  set_fzf_output $'\n\n* main'

  run __shirube_select_branch
  assert_success
  assert_output "$(printf 'select\nmain')"
}

@test "__shirube_select_branch: prints 'select' and stripped branch name for remote branch" {
  create_empty_mock "git"
  set_fzf_output $'\n\n  remotes/origin/feature/foo'

  run __shirube_select_branch
  assert_success
  assert_output "$(printf 'select\nfeature/foo')"
}

@test "__shirube_select_branch: prints 'new' and query string on ctrl-n" {
  create_empty_mock "git"
  set_fzf_output $'mybranch\nctrl-n\n'

  run __shirube_select_branch
  assert_success
  assert_output "$(printf 'new\nmybranch')"
}

@test "__shirube_select_branch: prints 'delete' and branch name on ctrl-r" {
  create_empty_mock "git"
  set_fzf_output $'\nctrl-r\n* main'

  run __shirube_select_branch
  assert_success
  assert_output "$(printf 'delete\nmain')"
}
