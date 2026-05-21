#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

# gh pr list output format: 123   Fix important bug   feature/fix   OPEN

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_select_pr: exits 1 with error when gh is not installed" {
  set_fzf_output ""

  run __shirube_select_pr
  assert_failure
  assert_output --partial "gh (GitHub CLI) is not installed"
}

@test "__shirube_select_pr: exits 1 when fzf is cancelled" {
  create_empty_mock "gh"
  set_fzf_output $'\n\n'

  run __shirube_select_pr
  assert_failure
}

@test "__shirube_select_pr: prints 'select' and PR number when PR is selected" {
  create_empty_mock "gh"
  set_fzf_output $'\n\n123   Fix important bug   feature/fix   OPEN'

  run __shirube_select_pr
  assert_success
  assert_output "$(printf 'select\n123')"
}

@test "__shirube_select_pr: prints 'open' and PR number on ctrl-o" {
  create_empty_mock "gh"
  set_fzf_output $'\nctrl-o\n123   Fix important bug   feature/fix   OPEN'

  run __shirube_select_pr
  assert_success
  assert_output "$(printf 'open\n123')"
}
