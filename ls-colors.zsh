0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

(){
	emulate -L zsh
	# load needed modules
	zmodload -F zsh/stat b:zstat

	# set the prefix for all functions
	local dir=${1:h} pfx=${2:-'ls-color'}
	shift 2

	# default to load all
	set -- $dir/lib/${^@}.zsh(N)
	(($#)) || set -- $dir/lib/*.zsh

	# load
	local file
	for file; source "$file" "$pfx"

} "$0" "$@"

# vim: set foldmethod=marker:
