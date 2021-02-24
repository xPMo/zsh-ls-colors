zmodload zsh/zutil
# args: context file [file ...]
# -o: output to stdout
# -0: output null-delimited to stdout
# -a: output to $reply as array
# -A: output to $reply as associative array
# -f FORMAT: use FORMAT if context's format is not set
# -F FORMAT: force FORMAT
${1:-ls-color}::fmt(){
	
	emulate -L zsh
	setopt cbases octalzeroes warncreateglobal

	local -a opt_out opt_format lscolors style_format
	local fmt
	zparseopts -D {0,o,a,A}=opt_out {f,F}:=opt_format
	case $opt_out in
		-o|-0) local -a reply=() ;;
		-A) typeset -gA reply=() ;;
		*) typeset -ga reply=() ;;
	esac

	# lookup list-colors for the current context
	zstyle -a "$1" list-colors lscolors
	zstyle -t "$1" list-colors-extended &&
		setopt extendedglob
	zstyle -a "$1" list-format style_format
	shift

	case $opt_format[1] in
		-F) fmt=${opt_format[2]} ;;
		*)  fmt=${style_format:-${opt_format[2]:-'%F%f%r%(h.%I%i. -> %L%l%r)'}} ;;
	esac
	local -A namecolors=(${(@s:=:)lscolors:#[[:alpha:]][[:alpha:]]=*})
	local -A modecolors=([lc]=$'\e[' [rc]=m [tc]=0 [sp]=0)
	modecolors+=(${(@Ms:=:)lscolors:#[[:alpha:]][[:alpha:]]=*})
	: ${modecolors[ec]:=$modecolors[lc]$modecolors[no]$modecolors[rc]}

	local REPLY target ln_target
	local final indicator lstat
	local -i st_mode mode_ugs
	for target; do
		local code= final=() indicator=()
		# Is this a file?
		if zstat -A lstat -L - "$target" 2>/dev/null; then
			st_mode=$lstat[3]
			ln_target=$lstat[14]

			# See man 7 inode for more info

			local -i reg=0 dir=0

			while # while ... continue ... break
				case $(( st_mode & 0170000 )) in
					# put the most common first
					$((0040000)) )
						indicator+=(/)
						# other-writable and sticky
						if ((st_mode & 01002 == 01002)) && [[ ${code::=$modecolors[tw]} != (|0|00) ]]
						then
						# other-writable
						elif ((st_mode & 00002)) && [[ ${code::=$modecolors[ow]} != (|0|00) ]]
						then
						# sticky
						elif ((st_mode & 01000)) && [[ ${code::=$modecolors[tw]} != (|0|00) ]];
						then
						# normal directory
						else code=$modecolors[di]
						fi
					;;
					$((0100000)) ) # regular file
						# executable
						((st_mode & 00111)) && indicator+=('*')
						# set-uid
						if ((st_mode & 04000)) && [[ ${code::=$modecolors[su]} != (|0|00) ]]
						then
						# set-gid
						elif ((st_mode & 02000)) && [[ ${code::=$modecolors[sg]} != (|0|00) ]]
						then
						# executable
						elif ((st_mode & 00111)) && [[ ${code::=$modecolors[ex]} != (|0|00) ]]
						then
						# normal file, check namecolors first
						else code=${namecolors[(k)$target]:-$modecolors[fi]}
						fi
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
						code=$modecolors[so]
						indicator+=('=')
					;;
					$((0060000)) )
						code=$modecolors[bd]
					;;
					$((0020000)) )
						code=$modecolors[cd]
					;;
					$((0010000)) )
						code=$modecolors[pi]
						indicator+=('|')
					;;
				esac

				final+=("$code")
				break # exit loop
			do; done
			# ln=target handling
			[[ $ln_target ]] && final=("${final[1]:/target/$final[2]}" "${final[2]}")
		fi

		zformat -f REPLY "$fmt" P:$target p:${target:a} f:${target:t} l:$ln_target h:${ln_target:+1} \
			i:$indicator[1] j:$indicator[2] r:$modecolors[ec] \
			I:$modecolors[lc]$modecolors[tc]$modecolors[rc] \
			F:$modecolors[lc]${final[1]:-${namecolors[(k)$target]:-$modecolors[no]}}$modecolors[rc] \
			L:$modecolors[lc]${final[2]:-${namecolors[(k)$ln_target]:-$modecolors[no]}}$modecolors[rc]

		case $opt_out in
			-A) reply[$target]=$REPLY ;;
			*)  reply+=("$REPLY") ;;
		esac
	done
	case $opt_out in
		-o) print -rC1 "${(@)reply}"  ;;
		-0) print -rNC1 "${(@)reply}" ;;
	esac
} # }}}
# vim: set foldmethod=marker:
