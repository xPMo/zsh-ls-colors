# zsh-ls-colors

A zsh library to use `LS_COLORS` in scripts or other plugins.

For a simple demo, see the `demo` script in this repo.

Begin by calling `ls-colors::init`.
This will set the arrays `ftcolors` and `namecolors`.

For more advanced usage,
instructions are located at top of the source files for `from-array` and `from-name`.
If a use case isn't adequately covered,
please open an issue!
