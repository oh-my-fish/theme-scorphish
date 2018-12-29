# name: scorphish

# This file is part of theme-scorphis

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>


function fish_greeting -d "what's up, fish?"
  set_color $fish_color_autosuggestion[1]
  uname -npsr
  uptime
  set_color normal
end
