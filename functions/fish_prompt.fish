# name: scorphish

# This file is part of theme-scorphish

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>


function _prompt_rubies -a color -d 'Display current Ruby (rvm/rbenv)'
  type -q ruby; or return
  [ "$theme_display_ruby" = 'no' ]; and return
  set -gx ruby_version
  if type -q rvm-prompt
    if [ "$RUBY_VERSION" != "$LAST_RUBY_VERSION" -o -z "$ruby_version" ]
      set -gx ruby_version (rvm-prompt i v g)
      set -gx LAST_RUBY_VERSION $RUBY_VERSION
    end
  else if type -q rbenv
    set -gx ruby_version (rbenv version-name)
  end
  if test -z "$ruby_version"; or [ (type -P ruby) != "$LAST_RUBY_PATH" ]
    set -gx ruby_version (ruby --version | cut -d\  -f2)
    set -gx LAST_RUBY_PATH (type -P ruby)
  end
  echo -n -s $color (echo -n -s $ruby_version | cut -d- -f2-)
end

function _prompt_virtualenv -a color -d "Display currently activated Python virtual environment"
  type -q python; or return
  [ "$theme_display_virtualenv" = 'no' ]; and return
  if [ "$VIRTUAL_ENV" != "$LAST_VIRTUAL_ENV" -o -z "$PYTHON_VERSION" ]
    set -gx PYTHON_VERSION (python --version 2>&1 | cut -d\  -f2)
    set -gx LAST_VIRTUAL_ENV $VIRTUAL_ENV
  end
  echo -n -s $color $PYTHON_VERSION
  set venv_name (basename "$VIRTUAL_ENV")
  test $venv_name = ".venv"; and set venv_name (basename (dirname "$VIRTUAL_ENV"))
  [ -n "$VIRTUAL_ENV" ]; and echo -n -s '@'$venv_name
end

function _prompt_rust -a color -d "Display currently activated Rust"
  type -q rustc; or return
  [ "$theme_display_rust" != 'yes' ]; and return
  if echo $history[1] | grep -q 'rustup default'; or not set -q RUST_VERSION
    set -U RUST_VERSION (rustc --version | cut -d\  -f2)
  end
  echo -n -s $color $RUST_VERSION
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
    echo -n -s $color (whoami)@(hostname) $sep_color '|'
  end
end

function _git_branch_name
  echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty 2> /dev/null)
end

function _git_ahead_count -a remote -a branch_name
  echo (command git log $remote/$branch_name..HEAD 2> /dev/null | \
    grep '^commit' | wc -l | tr -d ' ')
end

function _git_dirty_remotes -a remote_color -a ahead_color
  set current_branch (command git rev-parse --abbrev-ref HEAD 2> /dev/null)
  set current_ref (command git rev-parse HEAD 2> /dev/null)

  for remote in (git remote | grep 'origin\|upstream')

    set -l git_ahead_count (_git_ahead_count $remote $current_branch)

    set remote_branch "refs/remotes/$remote/$current_branch"
    set remote_ref (git for-each-ref --format='%(objectname)' $remote_branch)
    if test "$remote_ref" != ''
      if test "$remote_ref" != $current_ref
        if [ $git_ahead_count != 0 ]
          echo -n "$remote_color!"
          echo -n "$ahead_color+$git_ahead_count$normal"
        end
      end
    end
  end
end

function _prompt_versions -a blue gray green orange red append
  set -l prompt_rubies (_prompt_rubies $red)

  set -l prompt_virtualenv (_prompt_virtualenv $blue)

  set -l prompt_rust (_prompt_rust $orange)

  set -l prompt_node (_prompt_node $green)

  echo -n -e -s "$prompt_rubies $prompt_virtualenv $prompt_rust $prompt_node" | string trim | string replace -ar " +" "$gray|" | tr -d '\n'
end

function _prompt_git -a gray normal orange red yellow
  test "$theme_display_git" = no; and return
  set -l git_branch (_git_branch_name)
  test -z $git_branch; and return
  set git_branch (string replace -ar '(\.?[^/]{1})[^/]*/' '$1/' $git_branch)
  if test "$theme_display_git_dirty" = no
    echo -n -s $gray '‹' $yellow $git_branch $gray '› '
    return
  end
  set dirty_remotes (_git_dirty_remotes $red $orange)
  if [ (_is_git_dirty) ]
    echo -n -s $gray '‹' $yellow $git_branch $red '*' $dirty_remotes $gray '› '
  else
    echo -n -s $gray '‹' $yellow $git_branch $red $dirty_remotes $gray '› '
  end
end

function _prompt_pwd
  set_color -o cyan
  printf '%s' (prompt_pwd)
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

  printf $gray'['

  _prompt_whoami $gray $green

  if test "$theme_display_pwd_on_second_line" != yes
    _prompt_pwd
    printf '%s|' $gray
  end

  _prompt_versions $blue $gray $green $orange $red

  if test "$theme_display_command_duration_in_right_prompt" != yes
    printf '%s] ⏱  %0.3fs ' $gray (math $CMD_DURATION / 1000)
  else
    printf '%s] %s ' $gray (date +%H:%M:%S)
  end

  if set -q SCORPHISH_GIT_INFO_ON_FIRST_LINE
    set theme_display_git_on_first_line
  end

  if set -q theme_display_git_on_first_line
    _prompt_git $gray $normal $orange $red $yellow
  end

  if test "$theme_display_pwd_on_second_line" = yes
    printf $gray'\n‹'
    _prompt_pwd
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
