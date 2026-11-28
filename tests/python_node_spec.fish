source (path dirname (status filename))/helpers.fish

function python_part
  _prompt_virtualenv '' 2>&1
end

function node_part
  _prompt_node '' 2>&1
end

function both_parts
  echo "$(python_part) $(node_part)"
end

function start_python_node_test
  start_test
  fake_program $work/bin/python 'echo "Python 3.11.1"'
  fake_program $work/bin/node 'echo v20.1.0'
end

function replace_programs_twice_in_one_second
  set -eg LAST_PYTHON_KEY PYTHON_VERSION LAST_NODE_KEY NODE_VERSION
  set -l now (/bin/date +%Y%m%d%H%M.%S)
  fake_program $work/bin/python 'echo "Python 3.10.0"'
  fake_program $work/bin/node 'echo v18.0.0'
  set_old_time $work/bin/python $now
  set_old_time $work/bin/node $now
  set -g first_output "$(both_parts)"
  fake_program $work/bin/python 'echo "Python 3.10.1"'
  fake_program $work/bin/node 'echo v18.1.0'
  set_old_time $work/bin/python $now
  set_old_time $work/bin/node $now
end

function describe_python_node
  function before_all
    start_spec
  end

  function after_each
    end_test
  end

  function after_all
    end_spec
  end

  function it_looks_up_python_and_node_once_while_nothing_changes
    start_python_node_test
    assert_equal 1 (lookups_in_two_prompts python_part python)
    assert_equal 1 (lookups_in_two_prompts node_part node)
    assert_equal '3.11.1 v20.1.0' "$(both_parts)"
  end

  function it_looks_up_python_and_node_again_when_they_are_replaced
    start_python_node_test
    both_parts >/dev/null
    fake_program $work/bin/python 'echo "Python 3.12.0"'
    fake_program $work/bin/node 'echo v20.2.0'
    set_old_time $work/bin/python 202101010000
    set_old_time $work/bin/node 202101010000
    assert_equal 1 (lookups_in_two_prompts python_part python)
    assert_equal 1 (lookups_in_two_prompts node_part node)
    assert_equal '3.12.0 v20.2.0' "$(both_parts)"
  end

  function it_looks_up_python_and_node_again_when_PATH_selects_other_ones
    start_python_node_test
    both_parts >/dev/null
    fake_program $work/bin2/python 'echo "Python 3.13.0"'
    fake_program $work/bin2/node 'echo v22.0.0'
    set -gx PATH $work/bin2 $work/bin
    assert_equal '3.13.0 v22.0.0' "$(both_parts)"
  end

  function it_looks_up_python_and_node_again_when_their_symlinks_point_elsewhere
    start_test
    fake_program $work/cellar/python3.11/python 'echo "Python 3.11.9"'
    fake_program $work/cellar/python3.12/python 'echo "Python 3.12.9"'
    fake_program $work/cellar/node20/node 'echo v20.9.0'
    fake_program $work/cellar/node22/node 'echo v22.9.0'
    for target in python3.11/python node20/node
      /bin/ln -sfn $work/cellar/$target $work/bin/(path basename $target)
    end
    set_old_time $work/bin/python
    set_old_time $work/bin/node
    assert_equal '3.11.9 v20.9.0' "$(both_parts)"
    for target in python3.12/python node22/node
      /bin/ln -sfn $work/cellar/$target $work/bin/(path basename $target)
    end
    set_old_time $work/bin/python
    set_old_time $work/bin/node
    assert_equal '3.12.9 v22.9.0' "$(both_parts)"
  end

  function it_looks_up_python_and_node_again_when_VIRTUAL_ENV_and_NVM_BIN_change
    start_python_node_test
    both_parts >/dev/null
    clear_calls
    set -gx VIRTUAL_ENV /x/project/.venv
    set -gx NVM_BIN /x/nvm/v20/bin
    assert_equal '3.11.1@project v20.1.0' "$(both_parts)"
    assert_equal 1 (call_count python)
    assert_equal 1 (call_count node)
  end

  function it_shows_programs_replaced_twice_within_one_second_once_that_second_is_over
    start_python_node_test
    run_in_one_second replace_programs_twice_in_one_second
    assert_equal 0 $status
    assert_equal '3.10.0 v18.0.0' "$first_output"
    wait_for_next_second
    assert_equal '3.10.1 v18.1.0' "$(both_parts)"
    assert_equal 0 (lookups_in_two_prompts python_part python)
    assert_equal 0 (lookups_in_two_prompts node_part node)
    set -eg first_output
  end

  function it_shows_the_cached_versions_again_after_other_programs_failed
    start_python_node_test
    assert_equal '3.11.1 v20.1.0' "$(both_parts)"
    fake_program $work/bin2/python 'exit 1'
    fake_program $work/bin2/node 'exit 1'
    set -gx PATH $work/bin2 $work/bin
    assert_equal ' ' "$(both_parts)"
    set -gx PATH $work/bin
    assert_equal '3.11.1 v20.1.0' "$(both_parts)"
  end

  function it_prints_nothing_while_the_lookup_fails_and_recovers_afterwards
    start_python_node_test
    both_parts >/dev/null
    fake_program $work/bin/python 'exit 1'
    fake_program $work/bin/node 'exit 1'
    set_old_time $work/bin/python 202101010000
    set_old_time $work/bin/node 202101010000
    assert_equal ' ' "$(both_parts)"
    assert_equal 2 (lookups_in_two_prompts python_part python)
    assert_equal 2 (lookups_in_two_prompts node_part node)
    set -gx VIRTUAL_ENV /x/project/.venv
    assert_equal '' "$(python_part)"
    set -eg VIRTUAL_ENV
    fake_program $work/bin/python 'echo "Python 3.11.2"'
    fake_program $work/bin/node 'echo v20.1.1'
    set_old_time $work/bin/python 202101010000
    set_old_time $work/bin/node 202101010000
    assert_equal '3.11.2 v20.1.1' "$(both_parts)"
  end

  function it_uses_python3_when_there_is_no_python
    start_test
    fake_program $work/bin/python3 'echo "Python 3.14.0"'
    assert_equal 3.14.0 "$(python_part)"
  end

  function it_prints_nothing_without_node
    start_test
    assert_equal '' "$(node_part)"
  end

  function it_prints_nothing_and_runs_nothing_when_the_display_settings_are_off
    start_python_node_test
    set -g theme_display_virtualenv no
    set -g theme_display_node no
    assert_equal ' ' "$(both_parts)"
    assert_equal 0 (call_count python)
    assert_equal 0 (call_count node)
  end

  function it_adds_the_virtual_environment_name_or_the_parent_folder_of_a_dot_venv
    start_python_node_test
    set -gx VIRTUAL_ENV /x/envs/web
    assert_equal 3.11.1@web "$(python_part)"
    set -gx VIRTUAL_ENV /x/project/.venv
    assert_equal 3.11.1@project "$(python_part)"
  end
end
