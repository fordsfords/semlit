# semlit
Semi-Literate Documentation

SEMLIT is a system for writing detailed source code
documentation. It is inspired by
[Donald Knuth](http://en.wikipedia.org/wiki/Donald_knuth)'s 1994
paper "[Literate Programming](http://literateprogramming.com/knuthweb.pdf)".

## License

Copyright 2012, 2015 Steven Ford http://geeky-boy.com and licensed
"public domain" style under
[CC0](http://creativecommons.org/publicdomain/zero/1.0/): 
![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png "CC0")

To the extent possible under law, the contributors to this project have
waived all copyright and related or neighboring rights to this work.
This work is published from: United States.  The project home is
https://github.com/fordsfords/semlit

To contact me, Steve Ford, project owner, you can find my email address
at http://geeky-boy.com.  Can't see it?  Keep looking.

## Introduction

Semi-literate documentation (SEMLIT) is a system for deep source
code documentation in which a program's implementation is
described in great detail.  Excerpts of the code are
liberally included in the documentation.  A reader views the
documentation with a web browser in a split-screen mode, with the
heavily-annotated code excerpts on the left and a clean listing of
the full source on the right.  Clickable links allow the
reader to easily navigate between the two sides.

The easiest way to understand it is to take a look at the
[semi-literate document of SEMLIT itself](http://fordsfords.github.io/semlit/html/).
Scroll down the left frame, pretending you are reading the text, until you
find a code fragment.  Click on a line number.  That
block of code should appear on the right side, in-context - i.e.
the right side shows the plain source code, also with line
numbers.&nbsp; Now scroll the right side to a different area of
the code and click on a line number in the right frame.&nbsp; The
left side jumps to the location where that code block is described
in the documentation.  This kind of switching back and forth
between the documented source and the plain source facilitates
exploration of the code.

## Quick Start

These instructions assume that you are running on Unix with Perl
installed and in your PATH.  I have tried it on MacOS, and
Cygwin (on Windows 7), with minor alterations.

1. Get the [github project](https://github.com/fordsfords/semlit).
2. Build the package.  This also runs the tool on itself, producing the
semi-literate document:
<pre>
./bld.sh
</pre>
3. View the result by pointing a browser at: `html/index.html`
4. Copy the semlit programs to a desired location, presumably a directory
included in your PATH:
<pre>
cp bin/* $HOME/bin/
</pre>
5. Build the semi-literate documenation for a small example:
<pre>
cd example
ls
semlit.sh example.sldoc
ls
<pre>
6. Notice that, in addition to html files, the semlit tool created the `example_c.txt`
file, which is the raw C source code.  Point your browser at the `index.html` file to
see the semi-literate document for the example.  Near the top it has:

  * [example_c.txt](http:example_c.txt) - (right-click and save as "example.c")
main program.

  That link points to the `example_c.txt` file and allows it to be downloaded.

## Usage

There are two forms of usag.  The first invokes Perl:<br>
`perl` _semlit.plPath_` [-h] [-d `_delim_`] [-f `_fs_`] [-I `_dir_`] [-t `_tabstop_`] [`_sldocFiles_`]`<br>
The second is a convenience wrapper script:<br>
`semlit.sh` [-h] [-d `_delim_`] [-f `_fs_`] [-I `_dir_`] [-t `_tabstop_`] [`_sldocFiles_`]`

Where:

* _semlit.plPath_ - path to `semlit.pl` file.  E.g. `$HOME/bin/semlit.pl`
* `-h` - print help screen
* `-d` _delim_ - delimiter character at start and end of a semlit command.  (default to '=')
* `-f` _fs_ - field separator character within a semlit command.  (default to ',')
* `-I` _dir_ - directory to find files for 'srcfile' and 'include' commands.  (default to ".")  The "-I dir" option can be repeated.
* `-t` _tabstop_ - convert tabs to "tabstop" spaces.  (default to '4')
* _sldocFiles_ - zero or more input files.  If omitted, inputs from stdin.

The purpose of the shell script wrapper is to avoid having to enter the path to the
semlit.pl program file.

## Input Files

There are two kinds of input files that you provide to semlit:

* Document source in html format, normally named with the file extension "`.sldoc`",
* Source for program being documented, normally named with file extension "`.slsrc`",
in the target language format, with embedded semlit markup commands.

Normally, there is a master "`.sldoc`" file which references the other input files.
For example, the semlit program is itself documented in semlit style.  The file
`semlit.sldoc` is the master html file, which contains references to
`copyright.sldoc`, `semlit_pl.slsrc`, and `semlit_sh.slsrc`.

When the `semlit` program is run, it creates two kinds of output files:

* Documentation output, ready for display, with file extension "`.html`".
* Program output source, in target language format, stripped of semlit markup.

These output files are created in the current working directory.  I have found it
useful to run the program inside a sub-directory so that the output files are
separated from the input files.  For example, here is approximately how the SEMLIT
package doc is generated (in the "bld.sh" script):

```
mkdir html
cd html
perl ../semlit_pl.slsrc -I.. ../semlit.sldoc
cd ..
```

