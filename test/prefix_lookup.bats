#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

setup() {
  setup_mocks
  load_shirube
  # Fake readline bindings in the formats printed by `bind -X`, `bind -s`, `bind -p`.
  bind() {
    case "$1" in
      -X) printf '%s\n' '"\C-xw" "__shirube_worktree"' '"\C-xi": "__shirube_issue"' ;;
      -s) printf '%s\n' '"\C-xg": "\C-a\C-k __shirube_ghq\C-m"' ;;
      -p) printf '%s\n' '"\C-x\C-e": edit-and-execute-command' '"\C-x\\": self-insert' '"\C-xu": undo' ;;
    esac
  }
}

@test "__shirube_prefix_lookup: returns shell command for bind -x binding" {
  run __shirube_prefix_lookup w
  assert_success
  assert_output "-x __shirube_worktree"
}

@test "__shirube_prefix_lookup: accepts bind -X output with colon" {
  run __shirube_prefix_lookup i
  assert_success
  assert_output "-x __shirube_issue"
}

@test "__shirube_prefix_lookup: returns quoted macro for bind -s binding" {
  run __shirube_prefix_lookup g
  assert_success
  assert_output '"\C-a\C-k __shirube_ghq\C-m"'
}

@test "__shirube_prefix_lookup: returns function name for control key binding" {
  run __shirube_prefix_lookup $'\x05'
  assert_success
  assert_output "edit-and-execute-command"
}

@test "__shirube_prefix_lookup: does not confuse plain key with control key" {
  run __shirube_prefix_lookup u
  assert_success
  assert_output "undo"
}

@test "__shirube_prefix_lookup: handles backslash key" {
  run __shirube_prefix_lookup '\'
  assert_success
  assert_output "self-insert"
}

@test "__shirube_prefix_lookup: fails for unbound key" {
  run __shirube_prefix_lookup q
  assert_failure
  assert_output ""
}
