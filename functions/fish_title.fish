# name: scorphish

# This file is part of theme-scorphish

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>

function fish_title
  set -l bin_venv
  if test "$theme_display_virtualenv" = 'no' -o -z "$VIRTUAL_ENV"
    set bin_venv "($_)"
  else
    set -l venv (basename "$VIRTUAL_ENV")
    test "$venv" = ".venv"; and set venv (basename (dirname "$VIRTUAL_ENV"))
    set bin_venv "($_) <$venv>"
  end
  printf " %s %s [%s] " $bin_venv (prompt_pwd) (hostname)
end
