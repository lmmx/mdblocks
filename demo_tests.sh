source bashrc_mdblock_functions.sh

test_result_blocks=$(
  for test_pyfile in tests/test*.py
  do
    echo "\`--> Testing $test_pyfile\`"
    pybtickblock "$test_pyfile" --noclip
  done
)
if [[ $1 != "--noclip" ]]; then
  echo "$test_result_blocks" | xclip -sel clip
fi
echo "$test_result_blocks"
