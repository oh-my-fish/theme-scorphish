source (path dirname (status filename))/helpers.fish

function git_part
  _prompt_git '' '' '' '' '' 2>&1
end

function start_git_test
  start_test
  set -gx PATH $saved_PATH
  set -gx GIT_CONFIG_GLOBAL /dev/null
  set -gx GIT_CONFIG_NOSYSTEM 1
  set -g theme_display_git yes
  set -g theme_display_git_dirty yes
  /bin/mkdir repo
  cd repo
  command git init -q
  command git checkout -q -b feature/prompt-tests
  command git -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m test
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
end
