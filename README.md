## Scorphish

Compact. Sufficient.

![scorphish](https://user-images.githubusercontent.com/2112697/60178902-def52b80-97f2-11e9-961d-0f7c115ccc49.png)

### Left prompt

Abbreviated path, Ruby version and gemset, Python version and virtualenv, Rust
version, NodeJS version, Git information and last command execution time.

#### Configuration:

The following options can be added to `~/.config/fish/conf.d/omf.fish` to change
the appearance and behavior of left prompt.

 * To display current Rust version:

```fish
set -g theme_display_rust yes
```

 * To display current Node version:

```fish
set -g theme_display_node yes
```

> Note: Node version may be lazy loaded depending on which nvm plugin you're
> using

 * To display current working directory on a second line:

```fish
set -g theme_display_pwd_on_second_line yes
```

 * To display Git information on the first line:

```fish
set -g theme_display_git_on_first_line yes
```

 * To display command duration in right prompt:

```fish
set -g theme_display_command_duration_in_right_prompt yes

```

 * To omit only dirty status of current local Git repository and have
   a faster prompt:

```fish
set -g theme_display_git_dirty no
```

 * To omit information of current Git repository altogether:

```fish
set -g theme_display_git no

```

 * To omit current Ruby version and gemset:

```fish
set -g theme_display_ruby no

```

 * To omit current Python version and virtualenv:

```fish
set -g theme_display_virtualenv no

```

### Right prompt

Last command's exit code and current time

### Acknowledgments

This theme is based on Zish and Coffeandcode themes, many thanks to their
authors!

Enjoy!
