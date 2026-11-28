source (path dirname (status filename))/helpers.fish

function ruby_part
  _prompt_rubies '' 2>&1
end

function rbenv_lookups
  lookups_in_two_prompts ruby_part rbenv
end

function start_ruby_test
  start_test
  set -gx RBENV_ROOT $work/rbenv
  /bin/mkdir -p $RBENV_ROOT/versions/3.3.0
  set_old_time $RBENV_ROOT/versions
  write_file $RBENV_ROOT/version 3.3.0
  fake_program $work/bin/ruby 'echo "ruby 3.1.4p1 (fake)"'
  fake_program $work/bin/rbenv 'test "$RBENV_VERSION" = missing && exit 1
echo "${RBENV_VERSION:-3.3.0}"'
  /bin/mkdir -p $work/project/sub
  cd $work/project
end

function install_a_version_and_show_ruby
  set -eg LAST_RBENV_KEY ruby_version
  /bin/rm -rf $RBENV_ROOT/versions/3.4.0
  /bin/mkdir $RBENV_ROOT/versions/3.4.0
  /usr/bin/touch $RBENV_ROOT/versions
  ruby_part >/dev/null
end

function describe_ruby_version
  function before_all
    start_spec
  end

  function after_each
    end_test
  end

  function after_all
    end_spec
  end

  function it_looks_up_rbenv_once_while_nothing_changes
    start_ruby_test
    assert_equal 1 (rbenv_lookups)
    assert_equal 3.3.0 "$(ruby_part)"
    assert_equal 1 (call_count rbenv)
  end

  function it_looks_up_rbenv_again_when_RBENV_VERSION_changes
    start_ruby_test
    ruby_part >/dev/null
    set -gx RBENV_VERSION 3.2.0
    assert_equal 1 (rbenv_lookups)
    assert_equal 3.2.0 "$(ruby_part)"
  end

  function it_looks_up_rbenv_again_when_a_ruby_version_file_appears
    start_ruby_test
    ruby_part >/dev/null
    write_file .ruby-version 3.2.0
    assert_equal 1 (rbenv_lookups)
  end

  function it_looks_up_rbenv_again_when_the_ruby_version_file_changes
    start_ruby_test
    write_file .ruby-version 3.2.0
    ruby_part >/dev/null
    write_file .ruby-version 3.2.1
    assert_equal 1 (rbenv_lookups)
  end

  function it_looks_up_rbenv_again_when_a_ruby_version_file_appears_in_a_parent_directory
    start_ruby_test
    cd sub
    ruby_part >/dev/null
    write_file ../.ruby-version 3.2.0
    assert_equal 1 (rbenv_lookups)
  end

  function it_skips_an_empty_ruby_version_file_in_favour_of_the_one_in_a_parent_directory
    start_ruby_test
    write_file .ruby-version 3.2.0
    printf '' > sub/.ruby-version
    cd sub
    ruby_part >/dev/null
    write_file ../.ruby-version 3.2.1
    assert_equal 1 (rbenv_lookups)
  end

  function it_skips_an_empty_ruby_version_file_in_favour_of_the_global_version_file
    start_ruby_test
    printf '' > .ruby-version
    ruby_part >/dev/null
    write_file $RBENV_ROOT/version 3.4.0
    assert_equal 1 (rbenv_lookups)
  end

  function it_looks_up_rbenv_again_when_the_global_version_file_changes_but_keeps_its_change_time
    start_ruby_test
    ruby_part >/dev/null
    write_file $RBENV_ROOT/version 3.4.0
    assert_equal 1 (rbenv_lookups)
  end

  function it_looks_up_rbenv_again_when_a_version_is_installed
    start_ruby_test
    ruby_part >/dev/null
    /bin/mkdir $RBENV_ROOT/versions/3.4.0
    set_old_time $RBENV_ROOT/versions 202101010000
    assert_equal 1 (rbenv_lookups)
  end

  function it_looks_up_rbenv_again_after_the_second_in_which_a_version_was_installed
    start_ruby_test
    run_in_one_second install_a_version_and_show_ruby
    assert_equal 0 $status
    wait_for_next_second
    assert_equal 1 (rbenv_lookups)
  end

  function it_looks_up_rbenv_on_every_prompt_while_RBENV_DIR_is_set
    start_ruby_test
    ruby_part >/dev/null
    set -gx RBENV_DIR $work/project
    assert_equal 2 (rbenv_lookups)
  end

  function it_falls_back_to_ruby_and_asks_rbenv_again_while_rbenv_fails
    start_ruby_test
    fake_program $work/bin/rbenv 'exit 1'
    assert_equal 2 (rbenv_lookups)
    assert_equal 2 (call_count ruby)
    assert_equal 3.1.4p1 "$(ruby_part)"
  end

  function it_shows_the_cached_version_again_after_rbenv_failed_for_another_version
    start_ruby_test
    assert_equal 3.3.0 "$(ruby_part)"
    set -gx RBENV_VERSION missing
    assert_equal 3.1.4p1 "$(ruby_part)"
    set -eg RBENV_VERSION
    assert_equal 3.3.0 "$(ruby_part)"
  end

  function it_shows_a_version_without_its_prefix
    start_ruby_test
    set -gx RBENV_VERSION ruby-3.2.1
    assert_equal 3.2.1 "$(ruby_part)"
  end

  function it_looks_up_ruby_once_per_ruby_path_without_rbenv
    start_ruby_test
    /bin/rm $work/bin/rbenv
    assert_equal 1 (lookups_in_two_prompts ruby_part ruby)
    assert_equal 3.1.4p1 "$(ruby_part)"
    fake_program $work/bin2/ruby 'echo "ruby 3.0.7 (fake)"'
    set -gx PATH $work/bin2 $work/bin
    assert_equal 1 (lookups_in_two_prompts ruby_part ruby)
    assert_equal 3.0.7 "$(ruby_part)"
  end

  function it_looks_up_rbenv_again_after_a_prompt_without_rbenv
    start_ruby_test
    ruby_part >/dev/null
    /bin/mv $work/bin/rbenv $work/hidden-rbenv
    assert_equal 3.1.4p1 "$(ruby_part)"
    /bin/mv $work/hidden-rbenv $work/bin/rbenv
    assert_equal 1 (rbenv_lookups)
    assert_equal 3.3.0 "$(ruby_part)"
  end

  function it_looks_up_rbenv_again_after_a_prompt_with_rvm
    start_ruby_test
    ruby_part >/dev/null
    fake_program $work/bin/rvm-prompt 'echo ruby-3.0.0'
    set -gx RUBY_VERSION ruby-3.0.0
    assert_equal 3.0.0 "$(ruby_part)"
    /bin/rm $work/bin/rvm-prompt
    assert_equal 1 (rbenv_lookups)
    assert_equal 3.3.0 "$(ruby_part)"
  end

  function it_shows_nothing_and_runs_nothing_when_ruby_display_is_off
    start_ruby_test
    set -g theme_display_ruby no
    assert_equal '' "$(ruby_part)"
    assert_equal 0 (call_count rbenv)
    assert_equal 0 (call_count ruby)
  end
end
