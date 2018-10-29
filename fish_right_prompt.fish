function fish_right_prompt
  set -l exit_code $status
  if test $exit_code -ne 0
    set_color red
  else
    set_color green
  end
  printf '%d' $exit_code
  set_color -o 666
  echo '|'
  if test $theme_display_time -ne 0
    set_color -o 777
    printf '%s' (date +%H:%M:%S)
  end
  set_color normal
end
