function _scorphish_git_operation -d 'Print the git operation in progress, then the branch being rebased'
  set -l git_dir $GIT_DIR
  if test -z "$git_dir"
    set -l dir $PWD
    while not test -e $dir/.git
      test $dir = /; and return
      set dir (path dirname $dir)
    end
    set git_dir $dir/.git
    if test -f $git_dir
      read -l line < $git_dir
      set git_dir (string replace -r '^gitdir: ' '' -- $line)
      string match -q '/*' -- $git_dir; or set git_dir $dir/$git_dir
    end
  end
  set -l operation
  set -l files
  if test -d $git_dir/rebase-merge
    set operation rebase
    set files $git_dir/rebase-merge/{msgnum,end,head-name}
  else if test -d $git_dir/rebase-apply
    set files $git_dir/rebase-apply/{next,last}
    if test -f $git_dir/rebase-apply/rebasing
      set operation rebase
      set -a files $git_dir/rebase-apply/head-name
    else if test -f $git_dir/rebase-apply/applying
      set operation am
    else
      set operation am/rebase
    end
  else if test -f $git_dir/MERGE_HEAD
    set operation merge
  else if test -f $git_dir/CHERRY_PICK_HEAD
    set operation cherry-pick
  else if test -f $git_dir/REVERT_HEAD
    set operation revert
  else if test -f $git_dir/BISECT_LOG
    set operation bisect
  else
    return
  end
  set -l values
  for file in $files
    set -l value
    test -f $file; and read value < $file
    set -a values "$value"
  end
  test -n "$values[1]" -a -n "$values[2]"; and set operation "$operation $values[1]/$values[2]"
  echo $operation
  string replace -rf '^refs/heads/' '' -- "$values[3]"
end
