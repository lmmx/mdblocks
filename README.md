# mdblocks

Markdown code block generation convenience functions:

- `btickblock` for generic `STDOUT` blocks
- `pybtickblock` for Python commands and their `STDOUT` and/or `STDERR` blocks
- `shbtickblock` for shell commands and their `STDOUT` and/or `STDERR` blocks

For quickly generating reproducible code examples in documentation (READMEs etc.).
This README contains examples of their usage and resulting markdown output.

All of the above commands **write to clipboard and print to STDOUT in one command**,
and the latter two also **delimit STDOUT and/or STDERR** as appropriate to the input command.

## Markdown backtick blocks 

I've been writing READMEs in markdown, increasingly with many "backtick blocks"
which give examples of different ways to run the code (e.g. with certain parameters),
and typing out the backtick blocks manually gets repetitive.

Lots of examples follow but I presume you're already familiar with these in markdown.

A lot of developers like coding in the browser, and want to add on Javascript
to do tricks there. For speed of editing/iterating and completeness of keyboard
shortcuts I prefer the `vim` text editor to graphical interfaces (be it GitHub's
in-browser markdown editor or online/offline code notebooks/IDEs).

Even though I'm not using a Jupyter notebook, I find myself 'filling in for it',
repetitively typing out the opening backticks, annotating the block with the content
type (either its language for syntax highlighting, or clarifying that it's
`STDOUT` or `STDERR` so I can recognise at a glance what the block contains
and how it relates to the previous one), pasting in the code/output (perhaps
requiring redirection to capture STDERR), then remembering to close the block.

If you miss a single step you can ruin your whole document, and this might not
be visible at the time of writing, and you may not see it when you try to view it.

Obviously this is a task for a little scripted automation, _et voilà_.

- For further justification of this workflow compared to notebooks see [Motivation](#motivation).

- Note that all output becomes STDOUT, i.e. STDERR blocks do not go to STDERR (meaning the
  entire output can go to clipboard, a pager like `less`, or redirected to a log file).

## Installation

If you don't already have a bashrc dotfiles directory, here's how to make one
and then "install" these 3 functions (i.e. make them available in your shell
environment).

```sh
mkdir -p ~/dotfiles/bashrc/`
cp bashrc_mdblock_functions.sh ~/dotfiles/bashrc/`
echo "source ~/dotfiles/bashrc/bashrc_mdblock_functions.sh" >> ~/.bashrc
```

Personally I have the line `source ~/dotfiles/bashrc/bashrc_functions` in my `~/.bashrc`
and then that starts with the following block:

```sh
for bashrc_funcs_file in ~/dotfiles/bashrc/bashrc_functions_*; do
  source $bashrc_funcs_file;
done
```

You can append the file directly to your bashrc but that's not advisable.
Your `.bashrc` should be kept small (only the most important things) and
complexity stored elsewhere (ideally in categorised files, e.g. this file is
categorised as `_functions_md` where 'md' means 'markdown').

## Dependencies

- `xclip` copies the result to the clipboard (result will not print to TTY if this operation fails)
  - To remove dependency, edit the last line of the functions to only print to TTY
- `bash`
  - Other shells should be compatible
- `grep`
  - See [here](https://unix.stackexchange.com/a/430182/89254) for details of the
    requirements for the `grep` pipe buffer handling (done to avoid executing the
    command multiple times for each of `STDOUT` and `STDERR`)

## Examples

It seems it's not possible to nest these programs together (presumably as the process substitution
will use the same process names or numbers, etc., and this will lead to one becoming overridden and
subsequently its pipe freezing, and no output).

The good news is this means that to show all the functions I will demonstrate them in more than one
way.

The sections below go through examples with `btickblock`, `shbtickblock`, and `pybtickblock`.
- `btickblock` puts the contents of any file into a single backtick block
- `shbtickblock` executes a shell script and collates its standard output and/or error
- `pytickblock` executes a Python program and collates its standard output and/or error

All of these can be customised using `--noclip` (to prevent the results being sent to the clipboard)
and `--plain` (to prevent the first block being annotated, i.e. to prevent syntax highlighting
in markdown viewers)

`btickblock` can be customised using `--py` and `--sh` to change the backtick block annotation to
"py" and "sh" (i.e. to get only the file block rather than the output blocks the other commands give).

### Shell program demo

#### `btickblock`

Given a simple shell script, `btickblock` prints its code (`cat` to a variable and `echo`, no big deal)

- The command run here is `btickblock tests/test_out.sh --sh` which changes the backtick annotation to
  "sh" rather than "STDOUT".

```sh
printf "hello"
printf "..."
echo "world"
```

The markdown block you can see above (which will probably be coloured by a syntax highlighter)
was generated by the command above.

I can achieve the exact same result with text input from a pipe, permitted because the
`btickblock` function gets its input via a command-substituted `cat "$1"` call (to
[trim trailing newlines](https://unix.stackexchange.com/questions/17747/why-does-shell-command-substitution-gobble-up-a-trailing-newline-char)
and standardise files without an EOF newline), and so if we pass the filename as `-`
then `cat` reads STDIN over a pipe.

- The command run here is `cat tests/test_out.sh | btickblock - --sh`

```sh
printf "hello"
printf "..."
echo "world"
```

That's a trivial example: more realistically, perhaps I want to use `awk` to prepend line
numbers to my file (the awk `NR` variable stores each line number)

- The command run here is `awk '{print NR ": " $0}' tests/test_out.sh | btickblock - --sh`

```sh
1: printf "hello"
2: printf "..."
3: echo "world"
```

This isn't validly annotated as shell script with those line numbers though, so I can remove them
with the `--plain` flag

- The command run here is `awk '{print NR ": " $0}' tests/test_out.sh | btickblock - --plain`

```
1: printf "hello"
2: printf "..."
3: echo "world"
```

You might wish to make a `.bashrc` alias for `btickblock - --plain` (something easily tab-autocompleted)
if you find yourself using it a lot, so you can just pipe to that alias.

The other feature (which I can't demo the effect of) is that passing `--noclip` will prevent the results from
being copied to `xclip`'s clipboard.

#### `shbtickblock`

The following is an example of the output of `shbtickblock`, obtaining the output of the file we previously only
obtained the file contents of, `test_out.sh` in the `tests/` directory.

- The command run here is `shbtickblock tests/test_out.sh`

```sh
printf "hello"
printf "..."
echo "world"
```
⇣
```STDOUT
hello...world
```

At the time of writing, you can't execute a shell script passed in over the STDIN pipe, and results in
an empty STDOUT block. (This feature is on the [TODO](#TODO) list).

- E.g. `cat tests/test_out.sh | shbtickblock -`

```sh
printf "hello"
printf "..."
echo "world"
```
⇣
```STDOUT
```

Instead, you can use `btickblock` twice with the STDIN pipe input and `--noclip` then collect at the
end, usually using `()` (subshell
[grouping commands](https://www.gnu.org/software/bash/manual/bash.html#Command-Grouping)).

For example, let's modify `tests/test_out.sh` to print "hella" instead of "hello", using `sed`.

- The commands to run here are the following (I'll write this markdown block by hand this time):
  - ...making sure not to `echo -e` the `blockstring` variable in case it contains non-linebreak
    newlines (which would become expanded, i.e. ending the line midway), and `echo`ing twice because
    `xclip` gobbles up the STDOUT stream when it saves to clipboard.

```sh
blockstring=$(
  sed 's/hello/hella/' tests/test_out.sh | btickblock - --noclip --sh
  echo "⇣"
  sed 's/hello/hella/' tests/test_out.sh | bash | btickblock - --noclip
)
echo "$blockstring" | xclip -sel clip
echo "$blockstring"
```

- ...and that command gives the following desired report of the input and output block:

```sh
printf "hella"
printf "..."
echo "world"
```
```STDOUT
hella...world
```

(I will try and work this into the `shbtickblock` function, TBC)

### Python program demo

#### `pybtickblock`

The following script will demonstrate `pybtickblock`, and to display it in this README
I used the `btickblock` command (introduced above).

- The command run here is `btickblock demo_test.sh --sh`

```sh
source bashrc_mdblock_functions.sh

echo "--> Testing tests/test_out.py"
pybtickblock test_out.py
```

To run this script, I just use `bash` (or you can `chmod +x` it to run with `./`)

- The command run here is `bash demo_test.sh`

```py
print(1)
```
⇣
```STDOUT
1
```

A more useful but more complex version of the above command for a single test, is
scripted in the file `bash demo_py_tests.sh`, which loops over all the Python test files
to demonstrate the output of `pybtickblock`. (This was useful when developing it to check
the output for all combinations of STDOUT and/or STDERR, in cases of failure/success etc.)

Again, I can retrieve the contents of this program ahead of running it by `btickblock`

- The command run here is `btickblock demo_tests.sh --sh`

```sh
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
```

> (The output from this next command is very long so I delimit it with a vertical break,
> `---` in markdown, before and after)

- The command run here is `bash demo_tests.sh`

---

`--> Testing tests/test_err_fail.py`
```py
print(unprintable_variable)
```
⇣
```STDERR
Traceback (most recent call last): File "tests/test_err_fail.py", line 1, in <module>
print(unprintable_variable) NameError: name 'unprintable_variable' is not defined
```
`--> Testing tests/test_err_success.py`
```py
from sys import stderr
print(2, file=stderr)
```
⇣
```STDERR
2
```
`--> Testing tests/test_null.py`
```py
import sys
```
⇣
```STDOUT
```
`--> Testing tests/test_out_err.py`
```py
from sys import stderr
print(1)
print(2, file=stderr)
```
⇣
```STDOUT
1
```
⇓
```STDERR
2
```
`--> Testing tests/test_out_inline_nl.py`
```py
text = "1\n2,3\n4,5,6\n"
lines = text.rstrip("\n").split("\n")
numbers = []
for l in lines:
    for i in l.split(","):
        numbers.append(int(i))
print(f"{len(numbers)} numbers: {numbers}")
```
⇣
```STDOUT
6 numbers: [1, 2, 3, 4, 5, 6]
```
`--> Testing tests/test_out.py`
```py
print(1)
```
⇣
```STDOUT
1
```

---

## Motivation

The character map utility makes writing mathematical symbols (e.g. in the README for
[this repo](https://github.com/lmmx/ordered-powerset)) much easier, and is obviously more lightweight
than TeX, but furthermore it means I no longer search the web to get codepoints for things like Unicode
sub/superscripts (⁰₀₁¹² etc.) or mathematical symbols (e.g. ⋃ `U+22C3` N-ary union).

It therefore means **I don't need a web browser at all**, and can even disconnect from the web
entirely.

I find this is quite a different assumption from the status quo on how code and its documentation is
written (based on a misinterpretation of the idea of "literate programming").

A lot of developers like code notebooks, but for many cases they're overkill, showing all the
internals and claiming to display a clear 'literate' narrative when they actually involve wading
through non-narrative junk that should be organised properly as a package of code that is then
imported as tools/functions etc.

- Showing all the internals is not necessary to get across the "point" of the input-output
  relationship, and is not the real purpose of documentation.

In my initial half-formed thought, I saw this as being developers “misconstruing secondary
annotative display as site of primary (something something)”

> Each to their own, but iterating on code in a README then updating by [aliased] `xclip` makes me
> believe notebooks are a category error (misconstruing 2° annotative display as site of 1°
> something something…)
>
> Might write a function to create backtick blocks for a given file tho

— ([tweet tweet](https://twitter.com/permutans/status/1276472062232735748))

What I was trying to say was that display, as a _speech act_, is a performance distinct
from the speech act of executing code, and attempting to merge them under the name "documentation"
(ostensibly for efficiency) actually makes a 'category error' in effectively "believing
that code speaks for itself" and therefore "evading" the requirement to narrate its
action by a sleight of hand, redefining "nhttps://en.wikipedia.org/wiki/B2Carration" (as 'documentation') as simply presenting
the code (rather than annotating).

- It'd be as if you went up to a blackboard and ran through some mathematical equations without
  explaining their relevance (the explanation of relevance is the narration).
- This might be suitable for a mathematics proof in which the variables are standard concepts,
  but not for an applied field like software engineering (applied logic design).
- Another way of stating this is that a circuit diagram does not have the same qualities as
  an electronics manual.
- Moreover, a linear program is not necessarily best explained by the same linear map of its
  lines: not all lines of a program are worth displaying, but it's impossible to hide this
  complexity if you have decided to merge the acts of documentation and display.

I think this penultimate analogy gets to the real issue, which is that perhaps notebooks
are suitable for developer-to-developer (like
[B2B](https://en.wikipedia.org/wiki/Business-to-business)) but the modified notion of 'documentation'
to mean narration/explanation doesn't hold when the reader is the 'user' (more like
[B2C](https://en.wikipedia.org/wiki/B2C)).

## TODO

- Shell command execution, i.e. treat 'here documents'(?) (or however you call file literals
  piped over STDIN) the same as actual shell scripts
  - Is it possible to retrieve the full command from the history by `fc -e : 1`?
