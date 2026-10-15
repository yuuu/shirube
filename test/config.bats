#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

setup() {
  setup_mocks
  export SHIRUBE_CONFIG="$BATS_TEST_TMPDIR/config"
}

write_config() {
  printf '%s\n' "$@" > "$SHIRUBE_CONFIG"
}

@test "config: all modules are enabled without a config file" {
  load_shirube
  assert_equal "${__shirube_prefix_keys[*]}" "g:ghq w:worktree b:branch p:pr i:issue a:backlog"
  run type -t __shirube_history_command
  assert_output "function"
}

@test "config: off disables a module and skips loading it" {
  write_config "issue = off" "history=off"
  load_shirube
  assert_equal "${__shirube_prefix_keys[*]}" "g:ghq w:worktree b:branch p:pr a:backlog"
  run type -t __shirube_select_issue
  assert_failure
  run type -t __shirube_history_command
  assert_failure
}

@test "config: accepts comments, blank lines, and on/off synonyms" {
  write_config "# shirube config" "" "  ghq = false  # not used" "worktree = no" "branch = 0" "pr = off" "pr = on"
  load_shirube
  assert_equal "${__shirube_prefix_keys[*]}" "p:pr i:issue a:backlog"
}

@test "config: warns about unknown modules and invalid values" {
  write_config "foo = off" "ghq = maybe" "branch"
  run load_shirube
  assert_success
  assert_line --partial "config:1: unknown setting 'foo'"
  assert_line --partial "config:2: invalid value 'maybe' for ghq"
  assert_line --partial "config:3: unknown setting 'branch'"
}

@test "config: Ctrl+x is left unbound when no prefix module is enabled" {
  write_config "ghq = off" "worktree = off" "branch = off" "pr = off" "issue = off" "backlog = off"
  bind_calls="$BATS_TEST_TMPDIR/bind_calls"
  unset SHIRUBE_LOADED
  bind() { printf '%s\n' "$*" >> "$bind_calls"; }
  source "$BATS_TEST_DIRNAME/../shirube.sh"
  unset -f bind
  run cat "$bind_calls"
  assert_output '-x "\C-r": __shirube_insert history'
}

@test "config: binds each enabled module by its mode" {
  bind_calls="$BATS_TEST_TMPDIR/bind_calls"
  unset SHIRUBE_LOADED
  bind() { printf '%s\n' "$*" >> "$bind_calls"; }
  source "$BATS_TEST_DIRNAME/../shirube.sh"
  unset -f bind
  run cat "$bind_calls"
  assert_line '"\C-xg": "\C-u__shirube_run ghq\C-m"'
  assert_line '-x "\C-xi": __shirube_run_in_place issue'
  assert_line '-x "\C-xa": __shirube_run_in_place backlog'
  assert_line '-x "\C-r": __shirube_insert history'
  assert_line '"\C-x": "\C-x\C-_s\C-x\C-_a"'
}
