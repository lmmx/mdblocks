function btickblock () {
  bt_anno="STDOUT" # don't autodetect file extension?
  for flag in "$@"; do
    case $flag in
      (--noclip) noclip=true;;
      (--sh)     bt_anno="sh";;
      (--py)     bt_anno="py";;
      (--plain)  bt_anno="";;
    esac
  done
  PROG_str=$(cat "$1") # strip EOF whitespace
  bt="\`\`\`"
  blockstring=$(
    echo "$bt$bt_anno"
    echo "$PROG_str"
    echo "$bt"
  )
  if [[ $noclip != true ]]; then
    echo "$blockstring" | xclip -sel clip
  fi
  echo "$blockstring" 
}

function PYTHON_SIMPLE_CMD_PRINTER () {
  # Do not split command on colons inside [single-quoted] string literals
  # but escape the exclamation mark or bash expands it to an `fc` command
  colon_lookbehind_regex="(?<""!""\\)\'"
  python -c """from re import split, compile
amended_regex = r'$colon_lookbehind_regex'
print(amended_regex)
amended_regex
regex = compile(pattern=amended_regex)
rrace = r'$1'; print(rrace)
qs = split(regex, rrace)
print(qs)
"""
}

function PYTHON_FANCY_MULTILINE_CMD_PRINTER () {
  # Same function as PYTHON_MULTILINE_CMD_PRINTER but prints quoted string literals in red

  # https://stackoverflow.com/a/26110311/2668831
  #echo "$1" | perl -pe 's/(?<!\\)\x27/_/g' # this replaces only unescaped quotes with `_`
  #echo "$1" | perl -pe 's/(?<!\\)\x27/\\\\\x27/g' # and this replaces them with `\'`
  #echo "$1" | perl -pe 's/(?<!\\)\x27/\\\\\\\x27/g' # and this escapes the backslash `\\\'`
  
  # splitting regex compiles as `compile(r"(?<!\\)\x27")` and the raw string
  # prints as `'(?<!\\\\)\\x27'` note that quote marks are not part of the string

  # esc_seq --> "\\\\\\\x27" = "\\\\\\'" = "\\\\" + "\\'" = ("\"+\") + ("\"+"'")
  # i.e. escape sequence for "\" + "'" i.e. escaped form of an escaped single quote

  bash_dbl_bslash="\\\\" # only 2 when expanded in shell, then raw string makes 4 again
  colon_lookbehind_regex="(?<""!""$bash_dbl_bslash)\'"
  arg_esc="$(echo $1 | perl -pe 's/(?<!\\)\x27/\\\\\\\x27/g')"
  python -c """\
from re import compile, escape, split;
esc_rrace = r'$arg_esc';
qm = b'\x27'.decode();
esc_seq = escape('$bash_dbl_bslash') + fr'\{qm}';
rrace = esc_rrace.replace(esc_seq, qm);
clr_regex_raw_str = r'$colon_lookbehind_regex';
clr_regex = compile(clr_regex_raw_str);
qs = split(clr_regex, rrace);
ll = [''];
for i, x in enumerate(qs):
    if i % 2 == 0:
        c = split(';', x);
        for j, l in enumerate(c):
            if j % 2 == 0:
                ll[-1] += l;
            else:
                ll.append(l.lstrip());
    else:
        esc_quoted_text = f'\'{x}\''
        red_esc_quoted_text = f'\x1b[0;31m{esc_quoted_text}\x1b[0m'
        ll[-1] += red_esc_quoted_text;

if ll[0] == '':
    ll.pop(0);

print('\n'.join(ll));
"""
}

function PYTHON_MULTILINE_CMD_PRINTER () {
  # Same function as PYTHON_MULTILINE_CMD_PRINTER but does not add ANSI colour codes

  # https://stackoverflow.com/a/26110311/2668831
  #echo "$1" | perl -pe 's/(?<!\\)\x27/_/g' # this replaces only unescaped quotes with `_`
  #echo "$1" | perl -pe 's/(?<!\\)\x27/\\\\\x27/g' # and this replaces them with `\'`
  #echo "$1" | perl -pe 's/(?<!\\)\x27/\\\\\\\x27/g' # and this escapes the backslash `\\\'`
  
  # splitting regex compiles as `compile(r"(?<!\\)\x27")` and the raw string
  # prints as `'(?<!\\\\)\\x27'` note that quote marks are not part of the string

  # esc_seq --> "\\\\\\\x27" = "\\\\\\'" = "\\\\" + "\\'" = ("\"+\") + ("\"+"'")
  # i.e. escape sequence for "\" + "'" i.e. escaped form of an escaped single quote

  bash_dbl_bslash="\\\\" # only 2 when expanded in shell, then raw string makes 4 again
  colon_lookbehind_regex="(?<""!""$bash_dbl_bslash)\'"
  arg_esc="$(echo $1 | perl -pe 's/(?<!\\)\x27/\\\\\\\x27/g')"
  python -c """\
from re import compile, escape, split;
esc_rrace = r'$arg_esc';
qm = b'\x27'.decode();
esc_seq = escape('$bash_dbl_bslash') + fr'\{qm}';
rrace = esc_rrace.replace(esc_seq, qm);
clr_regex_raw_str = r'$colon_lookbehind_regex';
clr_regex = compile(clr_regex_raw_str);
qs = split(clr_regex, rrace);
ll = [''];
for i, x in enumerate(qs):
    if i % 2 == 0:
        c = split(';', x);
        for j, l in enumerate(c):
            if j % 2 == 0:
                ll[-1] += l;
            else:
                ll.append(l.lstrip());
    else:
        esc_quoted_text = f'\'{x}\''
        ll[-1] += esc_quoted_text;

if ll[0] == '':
    ll.pop(0);

print('\n'.join(ll));
"""
}

function pybtickblock () {
  bt_anno="py"
  fancy=true
  case $1 in
    (--noclip|--plain|--nofancy) initial_mdblock_arg=true;;
  esac
  start_n_flags=$# # Initial flag count
  flag_counter=0
  for flag in "$@"; do
    ((flag_count++))
    case $flag in
      (--noclip) noclip=true && shift;;
      (--plain)  bt_anno="" && shift;;
      (--unfancy) fancy=false && shift;;
      # -c Indicates a Python command and terminates the options list
      (-c) pycommand=true && cmd_count=$flag_count;; # Penultimate arg
    esac
  done # There are now $# flags
  if [[ $pycommand = true ]]; then
    all_args=( "$@" )
    # -c flag terminates Python's flag parser, and array index is 0-based so
    # can just reuse the 1-based index from the loop above to get the command
    cmd_arg="${all_args[cmd_count]}"
    python_flag="-c"
    # TODO: add the ability to use all flags with the `-c` flag
    python_arg="$cmd_arg" # passed to `python -c` rather than the file
    # TODO add function code to also ignore escaped colons
    # Split `-c` arg on `;` ignoring escaped quoted `;` to get equivalent multiline program
    py_arg_multiline=$(PYTHON_MULTILINE_CMD_PRINTER "$cmd_arg")
    if [[ $fancy = true ]]; then
      py_arg_multiline_red=$(PYTHON_FANCY_MULTILINE_CMD_PRINTER "$cmd_arg")
    fi
  else
    python_flag=''
    python_arg="$@"
  fi
  if [[ $# -lt $start_n_flags ]] && [[ "$initial_mdblock_arg" != true ]]; then
    echo "Hold up! Pass mdblock flags first so they can be shifted please" 1>&2
    return 2 # Exit early before invoking Python
  fi
  if [[ $pycommand = true ]]; then
    PROG_str=$(echo "$py_arg_multiline" | cat -)
    if [[ $fancy = true ]]; then
      PROG_str_red=$(echo "$py_arg_multiline_red" | cat -)
    fi
  else
    PROG_str=$(cat "$1") # strip EOF whitespace
  fi
  # The following safely obtains STDOUT and STDERR in variables
  # with only a single execution of the command, see Q&A link:
  # https://unix.stackexchange.com/a/430182/89254
  out= err= status=
  while IFS= read -r line; do
    case $line in
      (out:*)    out=$out${line#out:}$'\n';;
      (err:*)    err=$err${line#err:}$'\n';;
      (status:*) status=${line#status:};;
    esac
  done < <(
    {
      {
        if [[ -z "$python_flag" ]]; then
          python "$python_arg"
        else
          python "$python_flag" "$python_arg"
        fi |
          grep --label=out --line-buffered -H '^' >&3
        echo >&3 "status:${PIPESTATUS[0]}"
      } 2>&1 |
        grep --label=err --line-buffered -H '^'
    } 3>&1    
  )
  # The variable assignment introduces trailing whitespace
  OUT_str=$(echo "$out" | cat -) # strip EOF whitespace
  ERR_str=$(echo "$err" | cat -) # strip EOF whitespace
  STATUS_str=$(echo "$status" | cat -) # strip whitespace
  bt="\`\`\`"
  blockstring=$(
    echo "$bt$bt_anno"
    echo "$PROG_str" # Do NOT use `-e` in case of non-EOL "\n"
    printf "$bt\n⇣\n$bt"
    if [[ "$OUT_str" == "" ]]; then
      if [[ "$ERR_str" == "" ]]; then # Neither STDOUT nor STDERR
        echo -e "STDOUT\n$bt" # just empty STDOUT block
      else # No STDOUT
        echo "STDERR"
        echo "$ERR_str" # just STDERR block
        echo "$bt"
      fi
    elif [[ "$ERR_str" == "" ]]; then # No STDERR
      echo "STDOUT"
      echo "$OUT_str"
      echo "$bt" # just STDOUT block
    else # Both STDOUT and STDERR
      echo "STDOUT"
      echo "$OUT_str"
      echo -e "$bt\n⇓\n$bt"STDERR # OUT-ERR separator (⇓)
      echo "$ERR_str"
      echo "$bt"
    fi
  )
  ### repeat for fancy TTY printer (using PROG_str_red
  if [[ $pycommand = true ]] && [[ $fancy = true ]]; then
    fancy_blockstring=$(
      echo "$bt$bt_anno"
      echo "$PROG_str_red" # Do NOT use `-e` in case of non-EOL "\n"
      printf "$bt\n⇣\n$bt"
      if [[ "$OUT_str" == "" ]]; then
        if [[ "$ERR_str" == "" ]]; then # Neither STDOUT nor STDERR
          echo -e "STDOUT\n$bt" # just empty STDOUT block
        else # No STDOUT
          echo "STDERR"
          echo "$ERR_str" # just STDERR block
          echo "$bt"
        fi
      elif [[ "$ERR_str" == "" ]]; then # No STDERR
        echo "STDOUT"
        echo "$OUT_str"
        echo "$bt" # just STDOUT block
      else # Both STDOUT and STDERR
        echo "STDOUT"
        echo "$OUT_str"
        echo -e "$bt\n⇓\n$bt"STDERR # OUT-ERR separator (⇓)
        echo "$ERR_str"
        echo "$bt"
      fi
    )
  fi
  ### finished repeat for fancy TTY printer
  if [[ $noclip != true ]]; then
    echo "$blockstring" | xclip -sel clip
  fi
  if [[ $pycommand = true ]] && [[ $fancy = true ]]; then
    echo "$fancy_blockstring"
  else
    echo "$blockstring"
  fi
}

function shbtickblock () {
  alias defaultshell='$SHELL'
  bt_anno="sh"
  case $1 in
    (--noclip|--plain) initial_mdblock_arg=true;;
  esac
  start_n_flags=$# # Initial flag count
  for flag in "$@"; do
    case $flag in
      (--noclip) noclip=true && shift;;
      (--plain)  bt_anno="" && shift;;
    esac
  done # There are now $# flags
  if [[ $# -lt $start_n_flags ]] && [[ "$initial_mdblock_arg" != true ]]; then
    echo "Hold up! Pass mdblock flags first so they can be shifted please" 1>&2
    echo "There are now $# flags, we started with $start_n_flags" 1>&2
    return 2 # Exit early before invoking Python
  fi
  # ProcSub stops pipe hang if recurse to pybtickblock but still doesn't
  # successfully recurse to pybtickblock from a call to shbtickblock
  # so I have changed the proc. sub. lines below back (decremented 3)
  # and removed the following two lines which set up and release it:
  #exec 4>&1 5>&2
  #exec 4>&- 5>&-
  PROG_str=$(cat "$1") # strip EOF whitespace
  # The following safely obtains STDOUT and STDERR in variables
  # with only a single execution of the command, see Q&A link:
  # https://unix.stackexchange.com/a/430182/89254
  out= err= status=
  while IFS= read -r line; do
    case $line in
      (out:*)    out=$out${line#out:}$'\n';;
      (err:*)    err=$err${line#err:}$'\n';;
      (status:*) status=${line#status:};;
    esac
  done < <(
    {
      {
        defaultshell "$@" |
          grep --label=out --line-buffered -H '^' >&3
        echo >&3 "status:${PIPESTATUS[0]}"
      } 2>&1 |
        grep --label=err --line-buffered -H '^'
    } 3>&1    
    #      grep --label=out --line-buffered -H '^' >&6
    #    echo >&6 "status:${PIPESTATUS[0]}"
    #  } 5>&4 |
    #    grep --label=err --line-buffered -H '^'
    #} 6>&4
  )
  # The variable assignment introduces trailing whitespace
  OUT_str=$(echo "$out" | cat -) # strip EOF whitespace
  ERR_str=$(echo "$err" | cat -) # strip EOF whitespace
  STATUS_str=$(echo "$status" | cat -) # strip whitespace
  bt="\`\`\`"
  blockstring=$(
    echo "$bt$bt_anno"
    echo "$PROG_str" # Do NOT use `-e` in case of non-EOL "\n"
    printf "$bt\n⇣\n$bt"
    if [[ "$OUT_str" == "" ]]; then
      if [[ "$ERR_str" == "" ]]; then # Neither STDOUT nor STDERR
        echo -e "STDOUT\n$bt" # just empty STDOUT block
      else # No STDOUT
        echo "STDERR"
        echo "$ERR_str" # just STDERR block
        echo "$bt"
      fi
    elif [[ "$ERR_str" == "" ]]; then # No STDERR
      echo "STDOUT"
      echo "$OUT_str"
      echo "$bt" # just STDOUT block
    else # Both STDOUT and STDERR
      echo "STDOUT"
      echo "$OUT_str"
      echo -e "$bt\n⇓\n$bt"STDERR # OUT-ERR separator (⇓)
      echo "$ERR_str"
      echo "$bt"
    fi
  )
  if [[ $noclip != true ]]; then
    echo "$blockstring" | xclip -sel clip
  fi
  echo "$blockstring"
}
