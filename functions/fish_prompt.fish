# name: scorphish

# This file is part of theme-scorphish

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>


function _prompt_rubies -a color -d 'Display current Ruby (rvm/rbenv)'
  type -q ruby; or return
  [ "$theme_display_ruby" = 'no' ]; and return
  if type -q rvm-prompt
    if [ "$RUBY_VERSION" != "$LAST_RUBY_VERSION" -o -z "$ruby_version" ]
      set -gx ruby_version (rvm-prompt i v g)
      set -gx LAST_RUBY_VERSION $RUBY_VERSION
    end
  else if type -q rbenv
    set -gx ruby_version (rbenv version-name)
    test -z "$ruby_version"; and set -gx ruby_version (ruby --version | string split -f2 ' ')
  else if [ (type -P ruby) != "$LAST_RUBY_PATH" ]
    set -gx ruby_version (ruby --version | string split -f2 ' ')
    set -gx LAST_RUBY_PATH (type -P ruby)
  end
  echo -n -s $color (string replace -r '^[^-]*-' '' -- $ruby_version)
end

function _prompt_virtualenv -a color -d "Display currently activated Python virtual environment"
  set -l python_cmd python
  type -q $python_cmd; or set python_cmd python3
  type -q $python_cmd; or return
  [ "$theme_display_virtualenv" = 'no' ]; and return
  if [ "$VIRTUAL_ENV" != "$LAST_VIRTUAL_ENV" -o -z "$PYTHON_VERSION" ]
    set -gx PYTHON_VERSION ($python_cmd --version 2>&1 | string split -f2 ' ')
    set -gx LAST_VIRTUAL_ENV $VIRTUAL_ENV
  end
  echo -n -s $color $PYTHON_VERSION
  set venv_name (path basename -- "$VIRTUAL_ENV")
  test "$venv_name" = ".venv"; and set venv_name (path basename (path dirname -- "$VIRTUAL_ENV"))
  [ -n "$VIRTUAL_ENV" ]; and echo -n -s '@'$venv_name
end

function _rust_toolchain_file -a dir -d "Print the nearest rust-toolchain file from dir up"
  while not path filter -f $dir/rust-toolchain.toml $dir/rust-toolchain
    test $dir = /; and return
    set dir (path dirname $dir)
  end
end

# Everything that decides which rustc runs here. rustup writes `default` and
# `override` to settings.toml, and installs and updates replace a toolchain's
# bin/rustc. Fails while any of those files changed within the current second,
# and when the compiler is selected by path, which cannot be watched.
function _rust_version_key
  set -l rustup_home ~/.rustup
  set -q RUSTUP_HOME; and set rustup_home $RUSTUP_HOME
  set -l settings $rustup_home/settings.toml
  set -l compilers $rustup_home/toolchains/*/bin/rustc
  set -l rustc (command -s rustc)
  # rustup searches from the real directory, not through symlinks.
  set -l dir (path resolve .)
  set -l toolchain_file (_rust_toolchain_file $dir)
  # Overrides are kept per directory, so with any set the directory matters.
  set -l override_dir
  path is -fr $settings; and string match -qr '^\s*["\x27]' < $settings; and set override_dir $dir
  string join -- ' ' \
    "toolchain=$RUSTUP_TOOLCHAIN" \
    "home=$(path resolve $rustup_home)" \
    "rustc=$rustc" \
    "real=$(path resolve $rustc)" \
    "file=$toolchain_file" \
    "dir=$override_dir" \
    "rustc_time=$(path mtime $rustc)" \
    "settings_time=$(path mtime $settings)" \
    "file_time=$(path mtime $toolchain_file | string join ,)" \
    "compiler_times=$(path mtime $compilers | string join ,)"
  string match -q '*/*' -- "$RUSTUP_TOOLCHAIN"; and return 1
  for file in $toolchain_file
    string match -qr '^[^#]*\bpath["\x27]?\s*=' < $file; and return 1
  end
  # path mtime counts whole seconds, so another change could follow in this one.
  not contains 0 (path mtime -R $rustc $settings $compilers $toolchain_file)
end

function _prompt_rust -a color -d "Display currently activated Rust"
  type -q rustc; or return
  [ "$theme_display_rust" != 'yes' ]; and return
  set -l key (_rust_version_key)
  set -l key_settled $status
  if not set -q LAST_RUST_KEY; or test "$key" != "$LAST_RUST_KEY"
    set -eg LAST_RUST_KEY
    # Without RUSTUP_AUTO_INSTALL=0 a missing toolchain is downloaded here, silently.
    set -g RUST_VERSION (RUSTUP_AUTO_INSTALL=0 rustc --version 2>/dev/null | string split -f2 ' ')
    and test $key_settled -eq 0
    and set -g LAST_RUST_KEY $key
  end
  test -n "$RUST_VERSION"; and echo -n -s $color $RUST_VERSION
end

function _prompt_node -a color -d "Display currently activated Node"
  [ "$theme_display_node" != 'yes' ]; and return
  type -q node; or return
  type -q nvm; and begin; set -q NVM_BIN; or return; end # Lazy loading
  if [ "$NVM_BIN" != "$LAST_NVM_BIN" -o -z "$NODE_VERSION" ]
    set -gx NODE_VERSION (node --version)
    set -gx LAST_NVM_BIN $NVM_BIN
  end
  [ -n "$NODE_VERSION" ]; and echo -n -s $color $NODE_VERSION
end

function _prompt_whoami -a sep_color -a color -d "Display user@host if on a SSH session"
  if set -q SSH_TTY
    echo -n -s $color $USER@$hostname $sep_color '|'
  end
end

function _git_branch_name
  set -l branch (command git symbolic-ref --short HEAD 2> /dev/null)
  if test -z "$branch"
    set -l sha (command git rev-parse --short HEAD 2> /dev/null)
    test -n "$sha"; and set branch ":$sha"
  end
  echo $branch
end

function _prompt_versions -a blue gray green orange red
  set -l prompt_rubies (_prompt_rubies $red)
  set -l prompt_virtualenv (_prompt_virtualenv $blue)
  set -l prompt_rust (_prompt_rust $orange)
  set -l prompt_node (_prompt_node $green)
  echo -n -e -s "$prompt_rubies $prompt_virtualenv $prompt_rust $prompt_node" | string trim | string replace -ar " +" "$gray|"
end

function _prompt_git -a gray normal orange red yellow
  test "$theme_display_git" = no; and return
  if test "$theme_display_git_dirty" = no
    set -l git_branch (_git_branch_name)
    test -z "$git_branch"; and return
    set git_branch (string replace -ar '(\.?[^/]{1})[^/]*/' '$1/' $git_branch)
    echo -n -s $gray '‹' $yellow $git_branch $gray '› '
    return
  end
  set -l git_status (command git status --porcelain=v2 --branch --ignore-submodules=dirty 2> /dev/null)
  set -l git_branch (string replace -rf '^# branch\.head ' '' -- $git_status)
  test "$git_branch" = '(detached)'; and set git_branch :(string replace -rf '^# branch\.oid (.{7}).*' '$1' -- $git_status)
  test -z "$git_branch"; and return
  set git_branch (string replace -ar '(\.?[^/]{1})[^/]*/' '$1/' $git_branch)
  set -l dirty
  string match -qv '#*' -- $git_status; and set dirty '*'
  set -l ab (string match -r '^# branch\.ab \+(\d+) -(\d+)' -- $git_status)
  set -l remotes
  test -n "$ab[2]" -a "$ab[2]" != 0; and set -a remotes $orange'+'$ab[2]
  test -n "$ab[3]" -a "$ab[3]" != 0; and set -a remotes $orange'-'$ab[3]
  set -q remotes[1]; and set remotes $red'!' $remotes
  echo -n -s $gray '‹' $yellow $git_branch $red $dirty $remotes $gray '› '
end

function _prompt_pwd -a color
  printf '%s%s' $color (prompt_pwd)
end

function _prompt_status_arrows -a exit_code
  if test $exit_code -ne 0
    set arrow_colors 600 900 c00 f00
  else
    set arrow_colors 060 090 0c0 0f0
  end

  for arrow_color in $arrow_colors
    set_color $arrow_color
    printf '»'
  end
end

function fish_prompt
  set -l exit_code $status
  set -l gray (set_color 666)
  set -l blue (set_color blue)
  set -l red (set_color red)
  set -l normal (set_color normal)
  set -l yellow (set_color yellow)
  set -l orange (set_color ff9900)
  set -l green (set_color green)
  set -l cyan (set_color -o cyan)
  printf $gray'['
  _prompt_whoami $gray $green
  if test "$theme_display_pwd_on_second_line" != yes
    _prompt_pwd $cyan
    printf '%s|' $gray
  end
  _prompt_versions $blue $gray $green $orange $red

  if test "$theme_display_command_duration_in_right_prompt" != yes
    printf '%s] … %0.3fs ' $gray (math $CMD_DURATION / 1000)
  else
    printf '%s] %s ' $gray (date +%H:%M:%S)
  end

  if set -q SCORPHISH_GIT_INFO_ON_FIRST_LINE
    set theme_display_git_on_first_line
  end

  if set -q theme_display_git_on_first_line
    _prompt_git $gray $normal $orange $red $yellow
  end

  if test "$theme_display_pwd_on_second_line" = yes
    printf $gray'\n‹'
    _prompt_pwd $cyan
    printf $gray'›'
  end

  printf '\n'
  if not set -q theme_display_git_on_first_line
    _prompt_git $gray $normal $orange $red $yellow
  end
  _prompt_status_arrows $exit_code
  printf ' '

  set_color normal
end
