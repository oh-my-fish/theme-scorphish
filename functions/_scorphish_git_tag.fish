function _scorphish_git_tag -d 'Print the tag exactly on HEAD'
  command git describe --tags --exact-match HEAD 2>/dev/null
end
