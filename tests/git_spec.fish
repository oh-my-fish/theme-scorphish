source (path dirname (status filename))/helpers.fish

function git_part
  _prompt_git '' '' '' '' '' 2>&1
end

function start_git_test
  start_test
  set -gx PATH $saved_PATH
  set -gx GIT_CONFIG_GLOBAL /dev/null
  set -gx GIT_CONFIG_NOSYSTEM 1
  set -gx GIT_EDITOR true
  set -g theme_display_git yes
  set -g theme_display_git_dirty yes
  /bin/mkdir repo
  cd repo
  command git init -q
  command git checkout -q -b feature/prompt-tests
  command git -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m test
end

function run_git
  command git -c user.name=test -c user.email=test@example.com $argv >/dev/null 2>&1
end

function commit_file -a file text
  printf '%s\n' $text > $file
  run_git add $file
  run_git commit -m $text
end

# Leaves feature/prompt-tests two commits ahead of base, the first in conflict with it.
function make_conflicting_branches
  run_git checkout -b base
  commit_file file base
  run_git checkout feature/prompt-tests
  commit_file file feature
  commit_file other other
end

function describe_git_branch
  function before_all
    start_spec
  end

  function after_each
    end_test
  end

  function after_all
    end_spec
  end

  function it_shows_the_branch_with_its_folders_shortened
    start_git_test
    assert_equal '‹f/prompt-tests› ' "$(git_part)"
    set -g theme_display_git_dirty no
    assert_equal '‹f/prompt-tests› ' "$(git_part)"
  end

  function it_marks_uncommitted_changes
    start_git_test
    write_file new-file text
    assert_equal '‹f/prompt-tests*› ' "$(git_part)"
  end

  function it_shows_the_commit_on_a_detached_head
    start_git_test
    command git checkout -q --detach
    set -l commit (string sub -l 7 (command git rev-parse HEAD))
    assert_equal "‹:$commit› " "$(git_part)"
    set -g theme_display_git_dirty no
    assert_equal "‹:$(command git rev-parse --short HEAD)› " "$(git_part)"
  end

  function it_shows_nothing_when_git_display_is_off
    start_git_test
    set -g theme_display_git no
    assert_equal '' "$(git_part)"
  end

  function it_shows_a_rebase_stopped_on_a_conflict_with_the_branch_being_rebased
    start_git_test
    make_conflicting_branches
    run_git rebase base
    assert_equal '‹f/prompt-tests|rebase 1/2*› ' "$(git_part)"
    set -g theme_display_git_dirty no
    assert_equal '‹f/prompt-tests|rebase 1/2› ' "$(git_part)"
  end

  function it_shows_a_rebase_by_applying_patches
    start_git_test
    make_conflicting_branches
    run_git rebase --apply base
    assert_equal '‹f/prompt-tests|rebase 1/2*› ' "$(git_part)"
    set -g theme_display_git_dirty no
    assert_equal '‹f/prompt-tests|rebase 1/2› ' "$(git_part)"
  end

  function it_shows_a_merge_stopped_on_a_conflict
    start_git_test
    make_conflicting_branches
    run_git merge base
    assert_equal '‹f/prompt-tests|merge*› ' "$(git_part)"
    set -g theme_display_git_dirty no
    assert_equal '‹f/prompt-tests|merge› ' "$(git_part)"
  end

  function it_shows_a_cherry_pick_stopped_on_a_conflict
    start_git_test
    make_conflicting_branches
    run_git cherry-pick base
    assert_equal '‹f/prompt-tests|cherry-pick*› ' "$(git_part)"
  end

  function it_shows_a_revert_stopped_on_a_conflict
    start_git_test
    commit_file file one
    commit_file file two
    run_git revert HEAD~1
    assert_equal '‹f/prompt-tests|revert*› ' "$(git_part)"
  end

  function it_shows_a_patch_that_failed_to_apply
    start_git_test
    make_conflicting_branches
    command git format-patch -1 base --stdout > ../patch
    run_git am ../patch
    assert_equal '‹f/prompt-tests|am 1/1› ' "$(git_part)"
  end

  function it_shows_a_bisect_on_the_commit_it_checked_out
    start_git_test
    make_conflicting_branches
    run_git bisect start HEAD base~1
    assert_equal "‹:$(command git rev-parse --short=7 HEAD)|bisect› " "$(git_part)"
  end

  function it_shows_no_operation_once_it_ends
    start_git_test
    make_conflicting_branches
    run_git rebase base
    run_git rebase --abort
    assert_equal '‹f/prompt-tests› ' "$(git_part)"
    run_git merge base
    run_git merge --abort
    run_git bisect start HEAD base~1
    run_git bisect reset
    assert_equal '‹f/prompt-tests› ' "$(git_part)"
  end

  function it_shows_the_operation_of_a_linked_worktree_only_there
    start_git_test
    make_conflicting_branches
    run_git worktree add ../tree base
    cd ../tree
    run_git merge feature/prompt-tests
    assert_equal '‹base|merge*› ' "$(git_part)"
    cd ../repo
    assert_equal '‹f/prompt-tests› ' "$(git_part)"
  end

  function it_shows_the_operation_of_a_repository_moved_behind_a_relative_git_file
    start_git_test
    make_conflicting_branches
    run_git merge base
    /bin/mv .git ../moved
    write_file .git 'gitdir: ../moved'
    /bin/mkdir sub
    cd sub
    assert_equal '‹f/prompt-tests|merge*› ' "$(git_part)"
  end

  function it_shows_the_operation_from_a_folder_inside_the_repository
    start_git_test
    make_conflicting_branches
    run_git rebase base
    /bin/mkdir sub
    cd sub
    assert_equal '‹f/prompt-tests|rebase 1/2*› ' "$(git_part)"
  end

  function it_shows_the_operation_of_the_repository_set_in_git_dir
    start_git_test
    make_conflicting_branches
    run_git merge base
    set -gx GIT_DIR $work/repo/.git
    set -gx GIT_WORK_TREE $work/repo
    cd $work
    assert_equal '‹f/prompt-tests|merge*› ' "$(git_part)"
  end

  function it_shows_nothing_outside_a_repository
    start_git_test
    cd $work
    assert_equal '' "$(git_part)"
    set -g theme_display_git_dirty no
    assert_equal '' "$(git_part)"
  end
end
