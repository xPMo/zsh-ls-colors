# Zsh support for LS_COLORS

![Demo screenshot](https://raw.githubusercontent.com/xPMo/zsh-ls-colors/image/demo.png)

A zsh library to use `LS_COLORS` in scripts or other plugins.

For a simple demo, see the `demo` script in this repo.

For more advanced usage,
instructions are located at top of the source files for `from-mode` and `from-name`.
If a use case isn't adequately covered,
please [open an issue](https://github.com/xPMo/zsh-ls-colors/issues/) !

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
```

### Parameter namespacing

While indirect parameter expansion exists with `${(P)var}`,
it doesn't play nicely with array parameters,
and especially not with associative arrays.

There are multiple strategies to prevent unnecessary re-parsing:

**Call `init` in global scope.**
This pollutes global namespace but prevents re-parsing `$LS_COLORS` on every function call.
```zsh
ls-color::init
```

**Don't call init at all:**
This is only compatible with `::match-by`,
and reparses LS_COLORS each time,
but it doesn't pollute global namespace.

```zsh
ls-color::match-by $file lstat
```

**Initialize within a scope with local parameters.**
Best for not polluting global namespace when multiple filenames need to be parsed.

```zsh
(){
	local -A namecolors modecolors
	ls-color::init

	for arg; do
		...
	done
}
```

**Custom parameter:** Save the array value as your own custom parameter to copy back.
```zsh
(){ # initially
	local -A namecolors modecolors
	ls-color::init
	typeset -ga _my_modecolors=("${(@kv)modecolors}")    # you MUST use (@kv) to avoid losing empty entries
	typeset -ga _my_namecolors=("${(kv)namecolors[@]}")  # alternatively, use bash-style [@]
}

my-function(){
	local -A modecolors=("${(@)_my_modecolors}")         # you MUST use (@) to avoid losing empty entries
	local -A namecolors=("${_my_namecolors[@]}")         # alternatively, use bash-style [@]

	...
}
```

## About the plugin:

You can find the plugin at [xPMo/zsh-ls-colors](https://github.com/xPMo/zsh-ls-colors/).
