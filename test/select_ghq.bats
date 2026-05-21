#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_select_ghq: exits 1 with error when ghq is not installed" {
  set_fzf_output ""

  run __shirube_select_ghq
  assert_failure
  assert_output --partial "ghq is not installed"
}

@test "__shirube_select_ghq: exits 1 when fzf is cancelled" {
  create_mock "ghq" ""
  set_fzf_output ""

  run __shirube_select_ghq
  assert_failure
}

@test "__shirube_select_ghq: prints selected path on success" {
  create_mock "ghq" "/home/user/repos/foo"
  set_fzf_output "/home/user/repos/foo"

  run __shirube_select_ghq
  assert_success
  assert_output "/home/user/repos/foo"
}
