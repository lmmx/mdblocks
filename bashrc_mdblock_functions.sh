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

function pybtickblock () {
  bt_anno="py"
  for flag in "$@"; do
    case $flag in
      (--noclip) noclip=true;;
      (--plain)  bt_anno="";;
    esac
  done
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
        python "$1" |
          grep --label=out --line-buffered -H '^' >&3
        echo >&3 "status:${PIPESTATUS[0]}"
      } 2>&1 |
        grep --label=err --line-buffered -H '^'
    } 3>&1    
  )
  # The variable assignment introduces trailing whitespace
  OUT_str="$(echo $out | cat -)" # strip EOF whitespace
  ERR_str="$(echo $err | cat -)" # strip EOF whitespace
  STATUS_str="$(echo $status | cat -)" # strip whitespace
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

function shbtickblock () {
  bt_anno="sh"
  for flag in "$@"; do
    case $flag in
      (--noclip) noclip=true;;
      (--plain)  bt_anno="";;
    esac
  done
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
        sh "$1" |
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
  OUT_str="$(echo $out | cat -)" # strip EOF whitespace
  ERR_str="$(echo $err | cat -)" # strip EOF whitespace
  STATUS_str="$(echo $status | cat -)" # strip whitespace
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
