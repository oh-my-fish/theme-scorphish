## Scorphish

Compact. Sufficient.

![scorphish](https://cloud.githubusercontent.com/assets/2112697/17072736/e7515e4a-5040-11e6-8f5b-95d8bd51bd20.png)


### Left prompt
Abbreviated path, Ruby version and gemset, Python version and virtualenv, Rust
version, NodeJS version and Git information.

#### Additional information:

 * To display Rust version add the following to `~/.config/fish/config/fish`:

```fish
set -g theme_display_rust yes
```

 * To display Node version add the following to `~/.config/fish/config/fish`:

```fish
set -g theme_display_node yes
```

 * To display current working directory on a second line add the following to
   `~/.config/fish/config/fish`:

```fish
set -g theme_pwd_on_second_line
```

 * To display Git information on the first line add the following to
   `~/.config/fish/config/fish`:

```fish
set -g theme_git_info_on_first_line
```


### Right prompt
Last command's exit code and current time


### Acknowledgments
This theme is based on Zish and Coffeandcode themes, many thanks to their
authors!

Enjoy!
