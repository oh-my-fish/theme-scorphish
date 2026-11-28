source (path dirname (status filename))/helpers.fish

function rust_part
  _prompt_rust '' 2>&1
end

function rust_lookups
  lookups_in_two_prompts rust_part rustc
end

# fish prints the errors of builtins and redirections to its own standard
# error, which only a separate fish process lets us capture.
function two_rust_parts_in_new_fish
  set -l fish (status fish-path)
  $fish --no-config -c 'set -g theme_display_rust yes; source $argv[1]; echo (_prompt_rust "") (_prompt_rust "")' $prompt_file 2>&1
end

function fake_compiler -a home toolchain release
  write_program $home/toolchains/$toolchain/bin/rustc "echo 'rustc $release (fake)'"
end

function start_rust_test
  start_test
  set -gx RUSTUP_HOME $work/rustup
  write_file $RUSTUP_HOME/settings.toml 'default_toolchain = "stable"'
  fake_compiler $RUSTUP_HOME stable 1.80.0
  fake_compiler $RUSTUP_HOME nightly 1.82.0
  fake_program $work/bin/rustc 'echo "RUSTUP_AUTO_INSTALL=$RUSTUP_AUTO_INSTALL" >> "$CALLS_LOG"
toolchain=${RUSTUP_TOOLCHAIN:-stable}
case $toolchain in */*) ;; *) toolchain=$RUSTUP_HOME/toolchains/$toolchain;; esac
exec "$toolchain/bin/rustc" "$@"'
  /bin/mkdir -p $work/project/sub
  cd $work/project
end

function replace_compiler_twice_in_one_second
  set -eg LAST_RUST_KEY RUST_VERSION
  set -l now (/bin/date +%Y%m%d%H%M.%S)
  set -l compiler $RUSTUP_HOME/toolchains/stable/bin/rustc
  fake_compiler $RUSTUP_HOME stable 1.80.1
  set_old_time $compiler $now
  set -g first_output "$(rust_part)"
  fake_compiler $RUSTUP_HOME stable 1.80.2
  set_old_time $compiler $now
end

function describe_rust_version
  function before_all
    start_spec
  end

  function after_each
    end_test
  end

  function after_all
    end_spec
  end

  function it_looks_up_rustc_once_while_nothing_changes
    start_rust_test
    assert_equal 1 (rust_lookups)
    assert_equal 1.80.0 "$(rust_part)"
    assert_equal 1 (call_count rustc)
  end

  function it_looks_up_rustc_again_when_RUSTUP_TOOLCHAIN_changes
    start_rust_test
    rust_part >/dev/null
    set -gx RUSTUP_TOOLCHAIN nightly
    assert_equal 1 (rust_lookups)
    assert_equal 1.82.0 "$(rust_part)"
  end

  function it_looks_up_rustc_again_when_a_rust_toolchain_toml_file_appears
    start_rust_test
    rust_part >/dev/null
    write_file rust-toolchain.toml '[toolchain]' 'channel = "nightly"'
    assert_equal 1 (rust_lookups)
  end

  function it_looks_up_rustc_again_when_the_rust_toolchain_toml_file_changes
    start_rust_test
    write_file rust-toolchain.toml '[toolchain]' 'channel = "nightly"'
    rust_part >/dev/null
    set_old_time rust-toolchain.toml 202101010000
    assert_equal 1 (rust_lookups)
  end

  function it_looks_up_rustc_again_when_a_rust_toolchain_file_appears_in_a_parent_directory
    start_rust_test
    cd sub
    rust_part >/dev/null
    write_file ../rust-toolchain nightly
    assert_equal 1 (rust_lookups)
  end

  function it_looks_up_rustc_again_in_a_directory_with_another_toolchain_file_of_the_same_change_time
    start_rust_test
    write_file rust-toolchain.toml '[toolchain]' 'channel = "stable"'
    write_file sub/rust-toolchain.toml '[toolchain]' 'channel = "nightly"'
    rust_part >/dev/null
    cd sub
    assert_equal 1 (rust_lookups)
  end

  function it_finds_the_toolchain_file_from_the_real_directory_behind_a_symlink
    start_rust_test
    write_file rust-toolchain.toml '[toolchain]' 'channel = "nightly"'
    /bin/mkdir $work/elsewhere
    /bin/ln -s $work/project/sub $work/elsewhere/link
    cd $work/elsewhere/link
    rust_part >/dev/null
    set_old_time $work/project/rust-toolchain.toml 202101010000
    assert_equal 1 (rust_lookups)
    write_file $work/elsewhere/rust-toolchain.toml '[toolchain]' 'channel = "stable"'
    assert_equal 0 (rust_lookups)
  end

  function it_looks_up_rustc_again_when_settings_toml_changes
    start_rust_test
    rust_part >/dev/null
    write_file $RUSTUP_HOME/settings.toml 'default_toolchain = "nightly"'
    set_old_time $RUSTUP_HOME/settings.toml 202101010000
    assert_equal 1 (rust_lookups)
  end

  function it_looks_up_rustc_again_after_changing_directory_when_settings_toml_has_a_directory_override
    start_rust_test
    write_file $RUSTUP_HOME/settings.toml '[overrides]' '"/somewhere" = "nightly"'
    rust_part >/dev/null
    cd sub
    assert_equal 1 (rust_lookups)
  end

  function it_does_not_look_up_rustc_again_after_changing_directory_without_overrides
    start_rust_test
    rust_part >/dev/null
    cd sub
    assert_equal 0 (rust_lookups)
  end

  function it_recognises_indented_and_single_quoted_override_lines
    start_rust_test
    for line in '  "/somewhere" = "nightly"' "'/somewhere' = 'nightly'"
      cd $work/project
      write_file $RUSTUP_HOME/settings.toml '[overrides]' $line
      rust_part >/dev/null
      cd sub
      assert_equal 1 (rust_lookups)
    end
  end

  function it_prints_no_error_when_settings_toml_cannot_be_read
    start_rust_test
    /bin/chmod 000 $RUSTUP_HOME/settings.toml
    assert_equal '1.80.0 1.80.0' "$(two_rust_parts_in_new_fish)"
  end

  function it_looks_up_rustc_again_when_a_toolchain_compiler_is_replaced
    start_rust_test
    rust_part >/dev/null
    fake_compiler $RUSTUP_HOME stable 1.80.1
    set_old_time $RUSTUP_HOME/toolchains/stable/bin/rustc 202101010000
    assert_equal 1 (rust_lookups)
    assert_equal 1.80.1 "$(rust_part)"
  end

  function it_looks_up_rustc_again_when_RUSTUP_HOME_moves_to_a_folder_with_the_same_change_times
    start_rust_test
    rust_part >/dev/null
    /bin/cp -Rp $RUSTUP_HOME $work/rustup2
    fake_compiler $work/rustup2 stable 1.81.0
    set -gx RUSTUP_HOME $work/rustup2
    assert_equal 1 (rust_lookups)
    assert_equal 1.81.0 "$(rust_part)"
  end

  function it_keeps_rustc_cached_when_RUSTUP_TOOLCHAIN_starts_with_a_dash
    start_rust_test
    fake_compiler $RUSTUP_HOME -nightly 1.79.0
    set -gx RUSTUP_TOOLCHAIN -nightly
    assert_equal '1.79.0 1.79.0' "$(two_rust_parts_in_new_fish)"
    assert_equal 1 (call_count rustc)
  end

  function it_looks_up_rustc_on_every_prompt_when_the_toolchain_file_selects_a_path
    start_rust_test
    for line in 'path = "/opt/rust"' '"path" = "/opt/rust"' "'path' = '/opt/rust'"
      write_file rust-toolchain.toml '[toolchain]' $line
      assert_equal 2 (rust_lookups)
    end
  end

  function it_keeps_rustc_cached_when_the_toolchain_file_selects_a_channel
    start_rust_test
    write_file rust-toolchain.toml '[toolchain]' '# path = "/opt/rust"' 'channel = "nightly"'
    assert_equal 1 (rust_lookups)
  end

  function it_looks_up_rustc_on_every_prompt_when_RUSTUP_TOOLCHAIN_is_a_path
    start_rust_test
    set -gx RUSTUP_TOOLCHAIN $RUSTUP_HOME/toolchains/nightly
    assert_equal 2 (rust_lookups)
    assert_equal 1.82.0 "$(rust_part)"
  end

  function it_prints_nothing_while_rustc_fails_and_shows_the_cached_toolchain_again_afterwards
    start_rust_test
    assert_equal 1.80.0 "$(rust_part)"
    set -gx RUSTUP_TOOLCHAIN beta
    assert_equal '' "$(rust_part)"
    assert_equal 2 (rust_lookups)
    set -eg RUSTUP_TOOLCHAIN
    assert_equal 1.80.0 "$(rust_part)"
  end

  function it_shows_a_compiler_replaced_twice_within_one_second_once_that_second_is_over
    start_rust_test
    run_in_one_second replace_compiler_twice_in_one_second
    assert_equal 0 $status
    assert_equal 1.80.1 "$first_output"
    wait_for_next_second
    assert_equal 1.80.2 "$(rust_part)"
    assert_equal 0 (rust_lookups)
    set -eg first_output
  end

  function it_runs_rustc_with_RUSTUP_AUTO_INSTALL_set_to_0
    start_rust_test
    rust_part >/dev/null
    assert_equal RUSTUP_AUTO_INSTALL=0 "$(string match RUSTUP_AUTO_INSTALL=\* < $CALLS_LOG)"
  end
end
