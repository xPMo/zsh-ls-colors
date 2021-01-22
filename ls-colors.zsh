# set the prefix for all functions
local pfx=${1:-'ls-color'}

# load needed modules
zmodload -F zsh/stat b:zstat

# {{{ From mode
# Usage:
# $1: filename
# $2: The value of struct stat st_mode
#     If empty, modecolors lookup will be skipped
# $3: (If symlink) The value of struct stat st_mode
#     for the target of $1's symlink. If unset,
#     interpret as a broken link.
# Sets REPLY to the console code
${pfx}::from-mode () {
	# See man 7 inode for more info

	emulate -L zsh
	setopt cbases octalzeroes extendedglob

	[[ -z $2 ]] && return 1

	local -i reg=0
	local -a codes

	local -i st_mode=$(($2))
	# file type
	case $(( st_mode & 0170000 )) in
		$(( 0140000 )) ) codes=( $modecolors[so] ) ;;
		$(( 0120000 )) ) # symlink, special handling
			if ! (($+3)); then
				REPLY=$modecolors[or]
			elif [[ $modecolors[ln] = target ]]; then
				"$0" "$1" "${@:3}"
			else
				REPLY=$modecolors[ln]
			fi
			return
		;;
		$(( 0100000 )) ) codes=( ); reg=1 ;; # regular file
		$(( 0060000 )) ) codes=( $modecolors[bd] ) ;;
		$(( 0040000 )) ) codes=( $modecolors[di] ) ;;
		$(( 0020000 )) ) codes=( $modecolors[cd] ) ;;
		$(( 0010000 )) ) codes=( $modecolors[pi] ) ;;
	esac

	# setuid/setgid/sticky/other-writable
	(( st_mode & 04000 )) && codes+=( $modecolors[su] )
	(( st_mode & 02000 )) && codes+=( $modecolors[sg] )
	(( ! reg )) && case $(( st_mode & 01002 )) in
		# sticky
		$(( 01000 )) ) codes+=( $modecolors[st] ) ;;
		# other-writable
		$(( 00002 )) ) codes+=( $modecolors[ow] ) ;;
		# other-writable and sticky
		$(( 01002 )) ) codes+=( $modecolors[tw] ) ;;
	esac

	# executable
	if (( ! $#codes )); then
		(( st_mode &  0111 )) && codes+=( $modecolors[ex] )
	fi

	# return nonzero if no matching code
	[[ ${REPLY::=${(j:;:)codes}} ]]
} # }}}
# {{{ From name
# Usage:
# $1: filename
#
# Sets REPLY to the console code
${pfx}::from-name () {

	emulate -L zsh
	setopt extendedglob

	# Return non-zero if no keys match
	[[ ${REPLY::=$namecolors[(k)$1]} ]]
} # }}}
# {{{ Match by
# Usage:
# $1: filename
# Optional (must be $2): g[lobal]: Use existing stat | lstat in parent scope
# ${@:2}: Append to reply:
# - l[stat] : Look up using lstat (don't follow symlink), if empty match name
# - s[tat]  : Look up using  stat (do follow symlink), if empty match name
# - n[ame]  : Only match name
# - f[ollow]: Get resolution path of symlink
# - L[stat] : Same as above but don't match name
# - S[tat]  : Same as above but don't match name
# - a[ll]   : If a broken symlink: lstat follow lstat
#           : If a symlink       : lstat follow stat
#           : Otherwise          : lstat
# - A[ll]   : If a broken symlink: Lstat follow Lstat
#           : If a symlink       : Lstat follow Stat
#           : Otherwise          : Lstat
#
# or returns non-zero
${pfx}::match-by () {
	emulate -L zsh
	setopt extendedglob cbases octalzeroes

	local arg REPLY name=$1 pfx=${0%::match-by}
	shift

	# init in local scope if not using global params
	if ! [[ -v namecolors && -v modecolors ]]; then
		local -A namecolors modecolors
		${pfx}::init
	fi

	if [[ ${1:l} = (g|global) ]]; then
		shift
	else
		local -a stat lstat
		declare -ga reply=()
	fi

	zmodload -F zsh/stat b:zstat
	for arg; do case ${arg[1]:l} in
		n|name)
			${pfx}::from-name $name
			reply+=("$REPLY")
		;;
		l|lstat)
			(($#lstat)) || zstat -A lstat -L $name || return 1
			if ((lstat[3] & 0170000 )); then
				# follow symlink
				(($#stat)) || zstat -A stat $name 2>/dev/null
			fi
			${pfx}::from-mode "$name" "$lstat[3]" $stat[3]
			if [[ $REPLY || ${2[1]} = L ]]; then
				reply+=("$REPLY")
			else # fall back to name
				"$0" "$name" g n
			fi
		;;
		s|stat)
			(($#stat)) || zstat -A stat    $name || return 1
			${pfx}::from-mode $name $stat[3]
			reply+=("$REPLY")
			if [[ $REPLY || ${arg[1]} = S ]]; then
				reply+=("$REPLY")
			else # fall back to name
				"$0" "$name" g n
			fi
		;;
		f|follow)
			(($#lstat)) || zstat -A lstat -L $name || return 1
			reply+=("$lstat[14]")
		;;
		a|all)
			# Match case
			"$0" "$name" g ${${${arg[1]%a}:+L}:-l}
			# won't append if empty
			reply+=($lstat[14])
			# $stat[14] will be empty if not a symlink
			if [[ $lstat[14] ]]; then
				if [[ -e $name ]]; then
					"$0" "$name" g ${${${arg[1]%a}:+S}:-s}
				else
					reply+=($reply[-2])
				fi
			fi
		;;
		*) return 2 ;;
	esac; done
} # }}}
#{{{ Lookup
# $1: context
# $2: filename
# $3: mode of file (if not, will attempt to resolve file)
# $4: target of symlink (only applies if file is symlink)
# $5: mode of target (only applies if file is symlink)
${pfx}::lookup(){
	emulate -L zsh
	setopt cbases octalzeroes

	local pfx=${0%::lookup} style=$1 target=$2 ln_target=$4 ln_mode=$5
	local -a lscolors lstat

	# lookup list-colors for the current context
	zstyle -a "$style" list-colors lscolors
	zstyle -t "$style" list-colors-extended &&
		setopt extendedglob

	local -A namecolors=(${(@s:=:)lscolors:#[[:alpha:]][[:alpha:]]=*})
	local -A modecolors=(${(@Ms:=:)lscolors:#[[:alpha:]][[:alpha:]]=*})

	[[ -z $target ]] && return 1

	local -i st_mode=$3
	if ! (($#3)); then
		zstat -A lstat -L "$target"
		st_mode=$lstat[3]
		ln_target=$lstat[14]
	fi

	# See man 7 inode for more info

	local -i reg=0
	local -a codes

	# file type
	repeat 2; do # repeat if symlink
		case $(( st_mode & 0170000 )) in
			$(( 0140000 )) ) codes=( $modecolors[so] ) ;;
			$(( 0120000 )) ) # symlink, special handling
				# correct relative symlinks
				# does the target exist?
				if [[ -n $ln_mode ]] || zstat -A lstat "$target" 2>/dev/null; then
					if [[ $modecolors[ln] = target ]]; then
						# use $target:A instead of $ln_target to resolve symlink chains
						target=${target:A}
						st_mode=$(($lstat[3]))
						continue
					else
						REPLY=$modecolors[ln]
					fi
				else
					REPLY=$modecolors[or]
				fi
				return
			;;
			$(( 0100000 )) ) codes=( ); reg=1 ;; # regular file
			$(( 0060000 )) ) codes=( $modecolors[bd] ) ;;
			$(( 0040000 )) ) codes=( $modecolors[di] ) ;;
			$(( 0020000 )) ) codes=( $modecolors[cd] ) ;;
			$(( 0010000 )) ) codes=( $modecolors[pi] ) ;;
		esac

		# setuid/setgid/sticky/other-writable
		(( st_mode & 04000 )) && codes+=( $modecolors[su] )
		(( st_mode & 02000 )) && codes+=( $modecolors[sg] )
		(( ! reg )) && case $(( st_mode & 01002 )) in
			# sticky
			$(( 01000 )) ) codes+=( $modecolors[st] ) ;;
			# other-writable
			$(( 00002 )) ) codes+=( $modecolors[ow] ) ;;
			# other-writable and sticky
			$(( 01002 )) ) codes+=( $modecolors[tw] ) ;;
		esac
		break
	done

	# executable
	if (( ! $#codes )); then
		(( st_mode &  0111 )) && codes+=( $modecolors[ex] )
	fi

	REPLY=${(j:;:)codes}

	# return nonzero if no matching code
	[[ ${REPLY:=$namecolors[(k)$target]} ]]

} # }}}
# vim: set foldmethod=marker:
