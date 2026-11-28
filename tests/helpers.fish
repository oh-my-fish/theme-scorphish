set -g prompt_file (path resolve (path dirname (status filename))/../functions/fish_prompt.fish)
set -q SCORPHISH_PROMPT_FILE; and set prompt_file $SCORPHISH_PROMPT_FILE
source $prompt_file

set -g test_globals PATH fish_function_path CALLS_LOG \
  RUST_VERSION LAST_RUST_KEY RUSTUP_HOME RUSTUP_TOOLCHAIN \
  ruby_version RUBY_VERSION LAST_RBENV_KEY LAST_RUBY_VERSION LAST_RUBY_PATH RBENV_ROOT RBENV_VERSION RBENV_DIR \
  PYTHON_VERSION LAST_PYTHON_KEY VIRTUAL_ENV NODE_VERSION LAST_NODE_KEY NVM_BIN \
  theme_display_rust theme_display_ruby theme_display_virtualenv theme_display_node \
  theme_display_git theme_display_git_dirty GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM \
  GIT_EDITOR GIT_DIR GIT_WORK_TREE

function start_spec
  set -g test_start_dir $PWD
  for name in $test_globals
    set -eg saved_$name saved_exported_$name
    set -qg $name; or continue
    set -g saved_$name $$name
    set -qgx $name; and set -g saved_exported_$name
  end
  # The tests change directory into temporary folders, which must not reach
  # handlers such as z's, which records every directory visited.
  functions -e (functions --handlers-type variable | string replace -rf '^PWD (\S+)$' '$1')
  set -g program_cache (path resolve (/usr/bin/mktemp -d))
  set -g program_bodies
end

function end_spec
  /bin/rm -rf $program_cache
  set -eg program_cache program_bodies
end

function restore_globals
  for name in $test_globals
    set -eg $name
    set -qg saved_$name; or continue
    set -l saved saved_$name
    if set -qg saved_exported_$name
      set -gx $name $$saved
    else
      set -g $name $$saved
    end
  end
end

function start_test
  for name in $test_globals
    set -eg $name
  end
  set -g fish_function_path (path dirname $prompt_file)
  functions -e nvm node python python3 rbenv ruby rvm-prompt rustc
  set -g theme_display_rust yes
  set -g theme_display_ruby yes
  set -g theme_display_virtualenv yes
  set -g theme_display_node yes
  set -g work (path resolve (/usr/bin/mktemp -d))
  /bin/mkdir $work/bin
  set -gx CALLS_LOG $work/calls.log
  clear_calls
  set -gx PATH $work/bin
  cd $work
end

function end_test
  cd $test_start_dir
  /bin/rm -rf $work
  set -eg work
  restore_globals
end

function set_old_time -a file stamp
  test -n "$stamp"; or set stamp 202001010000
  /usr/bin/touch -h -t $stamp $file
end

function write_file -a file
  /bin/mkdir -p (path dirname $file)
  printf '%s\n' $argv[2..] > $file
  set_old_time $file
end

# macOS checks every new executable file the first time it runs, which costs
# up to a quarter second, so programs with the same text share one file.
function write_program -a file body
  set -l index (contains -i -- $body $program_bodies)
  if test -z "$index"
    set -a program_bodies $body
    set index (count $program_bodies)
    printf '#!/bin/sh\n%s\n' $body > $program_cache/$index
    /bin/chmod +x $program_cache/$index
  end
  /bin/mkdir -p (path dirname $file)
  /bin/ln -f $program_cache/$index $file
  set_old_time $file
end

function fake_program -a file body
  write_program $file 'echo "${0##*/} $*" >> "$CALLS_LOG"'\n$body
end

function clear_calls
  printf '' > $CALLS_LOG
end

function call_count -a program
  count (string match -r -- "^$program(?: |\$)" < $CALLS_LOG)
end

function lookups_in_two_prompts -a part program
  clear_calls
  $part >/dev/null
  $part >/dev/null
  call_count $program
end

function wait_for_next_second
  set -l now (/bin/date +%s)
  while test (/bin/date +%s) = $now
    /bin/sleep 0.05
  end
end

function run_in_one_second -a steps
  for try in 1 2 3
    set -l start (/bin/date +%s)
    $steps
    test (/bin/date +%s) = $start; and return
  end
  return 1
end
