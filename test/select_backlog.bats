#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

# bee issue list output format (after a header line, skipped by fzf):
# PROJ-12  未対応  タスク  中  Alice  Issue title

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_select_backlog: exits 1 with error when bee is not installed" {
  set_fzf_output ""

  run_minimal_path __shirube_select_backlog
  assert_failure
  assert_output --partial "bee (Backlog CLI) is not installed"
}

@test "__shirube_select_backlog: exits 1 when fzf is cancelled" {
  create_empty_mock "bee"
  set_fzf_output ""

  run __shirube_select_backlog
  assert_failure
}

@test "__shirube_select_backlog: prints issue key when issue is selected" {
  create_empty_mock "bee"
  set_fzf_output "PROJ-12  未対応  タスク  中  Alice  Issue title"

  run __shirube_select_backlog
  assert_success
  assert_output "PROJ-12"
}
