#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

# gh issue list output format: 456   Issue title   OPEN

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_select_issue: exits 1 with error when gh is not installed" {
  # gh is pre-installed at /usr/bin/gh on GitHub Actions runners, so restrict PATH.
  set_fzf_output ""

  run_minimal_path __shirube_select_issue
  assert_failure
  assert_output --partial "gh (GitHub CLI) is not installed"
}

@test "__shirube_select_issue: exits 1 when fzf is cancelled" {
  create_empty_mock "gh"
  set_fzf_output ""

  run __shirube_select_issue
  assert_failure
}

@test "__shirube_select_issue: prints issue number when issue is selected" {
  create_empty_mock "gh"
  set_fzf_output "456   Issue title   OPEN"

  run __shirube_select_issue
  assert_success
  assert_output "456"
}
