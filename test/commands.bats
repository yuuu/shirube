#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'helpers/common.bash'

setup() {
  setup_mocks
  load_shirube
}

@test "__shirube_ghq_command: quotes the selected path" {
  create_mock "ghq" ""
  set_fzf_output "/home/user/my repo"

  run __shirube_ghq_command
  assert_success
  assert_output 'builtin cd -- /home/user/my\ repo'
}

@test "__shirube_ghq_command: fails when cancelled" {
  create_mock "ghq" ""
  set_fzf_output ""

  run __shirube_ghq_command
  assert_failure
  assert_output ""
}

@test "__shirube_worktree_command: select jumps to the worktree" {
  create_mock "git" ""
  set_fzf_output $'\n\n/repo/.worktrees/foo  abc1234 [feature/foo]'

  run __shirube_worktree_command
  assert_success
  assert_output 'builtin cd -- /repo/.worktrees/foo'
}

@test "__shirube_worktree_command: ctrl-n creates a worktree under the main root" {
  create_mock "git" "/repo  abc1234 [main]"
  set_fzf_output $'feature/new\nctrl-n\n'

  run __shirube_worktree_command
  assert_success
  assert_output 'git worktree add /repo/.worktrees/feature/new -b feature/new && builtin cd -- /repo/.worktrees/feature/new && __shirube_worktree_copy_includes /repo /repo/.worktrees/feature/new'
}

@test "__shirube_worktree_command: ctrl-r removes the worktree" {
  create_mock "git" ""
  set_fzf_output $'\nctrl-r\n/repo/.worktrees/foo  abc1234 [feature/foo]'

  run __shirube_worktree_command
  assert_success
  assert_output '__shirube_worktree_remove /repo/.worktrees/foo feature/foo'
}

@test "__shirube_branch_command: builds checkout / new / delete commands" {
  create_mock "git" ""

  set_fzf_output $'\n\n  remotes/origin/feature/foo'
  run __shirube_branch_command
  assert_output 'git checkout feature/foo'

  set_fzf_output $'feature/new\nctrl-n\n'
  run __shirube_branch_command
  assert_output 'git checkout -b feature/new'

  set_fzf_output $'\nctrl-r\n  feature/old'
  run __shirube_branch_command
  assert_output 'git branch -d feature/old'
}

@test "__shirube_pr_command: builds checkout / open commands" {
  create_mock "gh" ""

  set_fzf_output $'\n\n42\tFix bug\tfix-bug\tOPEN'
  run __shirube_pr_command
  assert_output 'gh pr checkout 42'

  set_fzf_output $'\nctrl-o\n42\tFix bug\tfix-bug\tOPEN'
  run __shirube_pr_command
  assert_output 'gh pr view --web 42'
}

@test "__shirube_issue_command: opens the selected issue" {
  create_mock "gh" ""
  set_fzf_output $'7\tOPEN\tSome issue'

  run __shirube_issue_command
  assert_success
  assert_output 'gh issue view --web 7'
}

@test "__shirube_backlog_command: opens the selected issue" {
  export SHIRUBE_CONFIG="$BATS_TEST_TMPDIR/config"
  echo "backlog = on" > "$SHIRUBE_CONFIG"
  load_shirube
  create_mock "bee" ""
  set_fzf_output "PROJ-12  未対応  タスク  中  Alice  Issue title"

  run __shirube_backlog_command
  assert_success
  assert_output 'bee issue view --web PROJ-12'
}

@test "__shirube_run: evaluates the module command in the current shell" {
  __shirube_fake_command() { printf 'builtin cd -- %q' "$BATS_TEST_TMPDIR"; }
  __shirube_run fake
  assert_equal "$PWD" "$BATS_TEST_TMPDIR"
}

@test "__shirube_run: does nothing when cancelled" {
  __shirube_fake_command() { return 1; }
  run __shirube_run fake
  assert_success
  assert_output ""
}
