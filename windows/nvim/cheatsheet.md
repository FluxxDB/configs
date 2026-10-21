# Neovim cheat sheet

## Undo / redo
u              undo
Ctrl-r         redo
U              undo all changes on the current line
.              repeat last change

## Modes
i / a          insert before / after cursor
I / A          insert at start / end of line
o / O          open new line below / above
v / V          visual (characters) / visual (lines)
Ctrl-v         visual block (column select)
Esc            back to normal mode

## Moving around
h j k l        left, down, up, right
w / b / e      next word / previous word / end of word
0 / ^ / $      start of line / first non-blank / end of line
gg / G         top / bottom of file
42G or :42     go to line 42
Ctrl-d / Ctrl-u  scroll half page down / up
%              jump to matching bracket
f<char>        jump to next <char> on the line (; to repeat)
Ctrl-o / Ctrl-i  jump back / forward through jump history

## Editing
x              delete character
dd             delete (cut) line
yy             yank (copy) line
p / P          paste after / before
cw             change word
ciw            change the whole word under the cursor
ci" / ci(      change inside quotes / parentheses
>> / <<        indent / unindent line
J              join line below onto this one
~              toggle case
Alt-j / Alt-k  move line (or selection) down / up
gcc            toggle comment

## Search and replace
/text          search forward (n = next, N = previous)
*              search for word under cursor
:%s/old/new/g  replace all in file
:%s/old/new/gc replace all, confirming each

## Files and buffers
:w             save
:q / :q!       quit / quit discarding changes
:wq or ZZ      save and quit
Shift-h / Shift-l  previous / next buffer tab
:bd            close current buffer
Space bo       close all other buffers
Space bp       pin buffer

## Find (fzf-lua)
Space ff       find files
Space fg       grep across the project
Space fb       list open buffers
Space fr       recent files
Space fh       search help

## Explorer (neo-tree)
Space e        toggle file explorer
Space be       explorer on the Buffers tab
Space ge       explorer on the Git tab
?              (in tree) show all tree keys
a / d / r      (in tree) add / delete / rename
H              (in tree) toggle hidden files
e              (in tree) auto-fit width to long names
< / >          (in tree) switch Files / Buffers / Git tab

## Windows
Ctrl-w v / Ctrl-w s  split vertically / horizontally
Ctrl-w h/j/k/l       move to window left/down/up/right
Ctrl-w q             close window
Ctrl-w = / Ctrl-w < / Ctrl-w >  equalize / narrower / wider

## Help
Space ?        open this cheat sheet
Space k        search this cheat sheet + all keymaps
Space (pause)  which-key popup of leader keys
:help <topic>  built-in docs
