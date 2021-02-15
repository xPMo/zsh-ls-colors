local pfx=${1:-'ls-color'}

zmodload zsh/zutil
# args: context file [file ...]
# -o: output to stdout
# -a: output to $reply as array
# -A: output to $reply as associative array
# -f FORMAT: use FORMAT if context's format is not set
${pfx}::fmt(){
	
	emulate -L zsh
	setopt cbases octalzeroes

	local -a opt_{out,}
	zparseopts -D o=opt_out a=opt_out A=opt_out f=format

	# lookup list-colors for the current context
	zstyle -a "$1" list-colors lscolors
	zstyle -t "$1" list-colors-extended &&
		setopt extendedglob
	zstyle -a "$1" list-format format
	shift

	local -a format=(${format:-'%F%f%r%(h.%I%i. -> %L%l%r)'})
	local -A namecolors=(${(@s:=:)lscolors:#[[:alpha:]][[:alpha:]]=*})
	local -A modecolors=([lc]=$'\e[' [rc]=m [tc]=0 [sp]=0)
	modecolors+=(${(@Ms:=:)lscolors:#[[:alpha:]][[:alpha:]]=*})
	: ${modecolors[ec]:=$modecolors[lc]$modecolors[no]$modecolors[rc]}

	local REPLY target st_mode ln_target
	local -a codes final indicator lstat
	for target; do
		codes=() final=() indicator=()
		# Is this a file?
		if zstat -A lstat -L - "$target" 2>/dev/null; then
			st_mode=$lstat[3]
			ln_target=$lstat[14]

			# See man 7 inode for more info

			local -i reg=0

			while # while ... continue ... break
				case $(( st_mode & 0170000 )) in
					# put the most common first
					$((0040000)) )
						codes=( $modecolors[di] )
						indicator+=(/)
					;;
					$((0100000)) ) # regular file
						codes=( $modecolors[fi] )
						reg=1
					;;
					$((0120000)) ) # symlink, special handling
						indicator+=(@)
						# does the target exist?
						if zstat -A lstat - "$target" 2>/dev/null; then
							# restart with new st_mode
							st_mode=$(($lstat[3]))
							final=($modecolors[ln])
							continue
						else # broken link, we're done
							final=($modecolors[or] $modecolors[or])
							break
						fi
					;;
					$((0140000)) )
						codes=($modecolors[so])
						indicator+=('=')
					;;
					$((0060000)) )
						codes=($modecolors[bd])
						indicator+=('')
					;;
					$((0020000)) )
						codes=($modecolors[cd])
						indicator+=('')
					;;
					$((0010000)) )
						codes=($modecolors[pi])
						indicator+=('|')
					;;
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
				if (( ! $#codes && st_mode & 0111 )); then
					codes+=( $modecolors[ex] )
					indicator+=('*')
				fi
				final+=("${(j:;:)codes}")
				break # exit loop
			do; done
			# ln=target handling
			[[ $ln_target ]] && final=("${final[1]:/target/$final[2]}" "${final[2]}")
		fi

		zformat -f REPLY "$format" f:$target l:$ln_target h:${ln_target:+1} r:$modecolors[ec] \
			i:$indicator[1] j:$indicator[2] I:$modecolors[lc]$modecolors[tc]$modecolors[rc] \
			F:$modecolors[lc]${final[1]:-${namecolors[(k)$target]:-$modecolors[no]}}$modecolors[rc] \
			L:$modecolors[lc]${final[2]:-${namecolors[(k)$ln_target]:-$modecolors[no]}}$modecolors[rc]

		case $opt_out in
			-A) reply[$target]=$REPLY ;;
			-o) print -rl "$REPLY" ;;
			*)  reply+=("$REPLY") ;;
		esac
	done
} # }}}
# vim: set foldmethod=marker:
