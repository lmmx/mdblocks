## TODO

- Move this TODO list to issue tracker?
- Add syntax highlighting with ANSI codes for TTY printing? Is there a Python lib?
- Test if `pybtickblock` escapes work in Python 3.6 and update dependencies

The trickier parts left to do involve 'here documents' or file literals, i.e. strings sent
over a pipe or otherwise entered as STDIN which get treated as a file

- Shell command execution, i.e. treat 'here documents'(?) (or however you call file literals
  piped over STDIN) the same as actual shell scripts
  - Is it possible to retrieve the full command from the history by `fc -e : 1`?
- Improvements to `pybtickblock` when used with the `-c` flag to `python`
  - Add the ability to use all flags with the `-c` flag to `pybtickblock`
    - Currently, `-c` will 'consume' all other flags (it is possible to pass as `$python_arg`)
  - Add function code to also ignore escaped colons (as for escaped single quotes)
  - Print fancy text to TTY and non-fancy to clipboard
