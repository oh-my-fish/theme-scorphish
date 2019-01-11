# name: scorphish

# This file is part of theme-scorphis

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>


function fish_title
  if [ "$theme_display_virtualenv" = 'no' -o -z "$VIRTUAL_ENV" ]
    printf '(%s) %s' $_ (prompt_pwd)
  else
    printf '(%s) %s' (basename "$VIRTUAL_ENV") (prompt_pwd)
  end
end
