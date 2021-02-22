# Zsh support for LS_COLORS

![Demo screenshot](https://raw.githubusercontent.com/xPMo/zsh-ls-colors/image/demo-new.png)

A zsh library to use `LS_COLORS` in scripts or other plugins.

For a simple demo, see the `zstyle-demo` script in this repo.

If a use case isn't adequately covered,
please [open an issue](https://github.com/xPMo/zsh-ls-colors/issues/)!

Finally, if you are making use of this plugin, [add it to the wiki](https://github.com/xPMo/zsh-ls-colors/wiki/Uses-in-the-wild)!

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

## API v2:

This function takes a context and a list of files as input,
and returns a list of colored strings, formatted according to `$format`.

```zsh
${prefix}::fmt [ -f $format | -F $format ] [ -o | -0 | -a | -A ] $context $files[@]
```

### Loading the library

Since functions are a public namespace,
This library allows you to customize the preifix for your plugin:

```zsh
# load function as my-lscolors::fmt
# The remaining arguments to source determines which lib/ files you want to load.
# If no arguments are provided, then all lib/*.zsh are loaded.
source ${0:h}/ls-colors/ls-colors.zsh my-lscolors fmt
```

### Customizing Colors with styles

The `::fmt` function uses the usual `list-colors` style to determine how to color the results.
Set the style as follows:

```zsh
# Uses LS_COLORS format
zstyle $pattern list-colors ${(s[:])LS_COLORS} '*.ext=1'
```

In addition, you can enable `extendedglob` for certain contexts:

```zsh
zstyle $pattern list-colors-extended true
zstyle $pattern list-colors ${(s[:])LS_COLORS} '(#i).ext=1'
```

_Personally, I like this method for dynamically getting LS_COLORS for all contexts:_

```zsh
zstyle -e '*' list-colors 'reply=(${(s[:])LS_COLORS})'
```

### Customizing format with styles

The `::fmt` function uses the `list-format` style to determine how to format the results.
Set the style as follows:

```zsh
zstyle $pattern list-format '%F%P%r%(h.%I%i. -> %L%l%r)'
```

| Format specifier | Meaning | Example (`PWD=/usr`, `./bin/sh` symlinked to `dash`) |
| --- | --- | --- |
| `%F` | The color/console codes which match the file | `\e[0m\01;36m` |
| `%f` | The file basename | `sh` |
| `%P` | The file path provided | `./bin/sh` |
| `%p` | The fully-qualified path | `/usr/bin/sh` |
| `%L` | The color/console codes which match the target of the symlink | `\e[0m\e[01;32m` |
| `%l` | The target of the symlink | `dash` |
| `%h` | `1` if this file is a symlink, otherwise empty (useful to conditionally output the link target) | `1` |
| `%r` | The color/console codes normally used to reset the terminal style | `\e[0m` |
| `%I` | The color for filetype indicators | `\e[0m` |
| `%i` | The single-character filetype indicator the given file | `@` |
| `%j` | The single-character filetype indicator for the target of the symlink | `*` |

For more information on using these codes, see the section on `zformat` in `man zshmodules`.

More format specifiers may be added in the future, probably based on GNU find's `-printf` formats.

### Customizing format at runtime

There are two flags to the `::fmt` function which change how `list-format` is used:

```zsh
${prefix}::fmt -f $format     # use $format if no list-format is specified for the current style
${prefix}::fmt -F $format     # force $format, ignore the list-format specified for the current style
```

### Output method

There are four ways `::fmt` can return its results:

```zsh
${prefix}::fmt -a ...     # [default] assign results to $reply as an array
${prefix}::fmt -A ...     # assign results to $reply as an associative array, with filenames as keys
${prefix}::fmt -o ...     # print results to stdout separated by newlines
${prefix}::fmt -0 ...     # print results to stdout separated by NUL characters
```


## Legacy API:

For more advanced usage,
instructions are located at top of the source files for `from-mode` and `from-name`.

### Function namespacing

Since functions are a public namespace,
this plugin allows you to customize the preifix for your plugin:

```zsh
# load functions as my-lscolors::{init,match-by,from-name,from-mode}
# The remaining arguments to source determines which lib/ files you want to load.
# If no arguments are provided, then all lib/*.zsh are loaded.
source ${0:h}/ls-colors/ls-colors.zsh my-lscolors legacy
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
