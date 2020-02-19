# zsh-ls-colors

![Demo screenshot](https://raw.githubusercontent.com/xPMo/zsh-ls-colors/image/demo.png)

A zsh library to use `LS_COLORS` in scripts or other plugins.

For a simple demo, see the `demo` script in this repo.

For more advanced usage,
instructions are located at top of the source files for `from-mode` and `from-name`.
If a use case isn't adequately covered,
please open an issue!

## Using zsh-ls-colors in a plugin

You can use this as a submodule or a subtree.

### submodule:

```sh
# Add (only once)
git submodule add git://github.com/xPMo/zsh-ls-colors.git ls-colors
git commit -m 'Add ls-colors as submodule'

# Update
cd ls-colors
git fetch
git checkout origin/master
cd ..
git commit ls-colors -m 'Update ls-colors to latest'
```

### Subtree:

```sh
# Initial add
git subtree add --prefix=ls-colors/ --squash -m 'Add ls-colors as a subtree' \
	git://github.com/xPMo/zsh-ls-colors.git master

# Update
git subtree pull --prefix=ls-colors/ --squash -m 'Update ls-colors to latest' \
	git://github.com/xPMo/zsh-ls-colors.git master 


# Or, after adding a remote:
git remote add ls-colors git://github.com/xPMo/zsh-ls-colors.git

# Initial add
git subtree add --prefix=ls-colors/ --squash -m 'Add ls-colors as a subtree' ls-colors master

# Update
git subtree pull --prefix=ls-colors/ --squash -m 'Update ls-colors to latest' ls-colors master 
```

### Function namespacing

Since functions are a public namespace,
this plugin allows you to customize the preifix for your plugin:

```zsh
# load functions as my-lscolors::{init,match-by,from-name,from-mode}
source ${0:h}/ls-colors/ls-colors.zsh my-lscolors

my-lscolors::init
...
```


