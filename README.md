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
In other words, you can use this code for any purpose without any
restrictions.  This work is published from: United States.  The project home
is https://github.com/fordsfords/semlit

To contact me, Steve Ford, project owner, you can find my email address
at http://geeky-boy.com.  Can't see it?  Keep looking.

## Introduction

Semi-literate documentation (SEMLIT) is a system for deep source
code documentation in which a program's implementation is
described in detail.  Excerpts of the code are
liberally included in the documentation.  A reader views the
documentation with a web browser in a split-screen mode, with
heavily-annotated code excerpts on the left, and a clean listing of
the full source on the right.  Clickable links allow the
reader to easily navigate between the two sides.

The easiest way to understand it is to take a look at the
[semi-literate document of SEMLIT itself](http://fordsfords.github.io/semlit/html/).
Scroll down the left frame, pretending you are reading the text, until you
find a code fragment.  Click on a line number.  That
block of code should appear on the right side, in-context - i.e.
the right side shows the plain source code, also with line
numbers.  Now scroll the right side to a different area of
the code and click on a line number in the right frame.  The
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
</pre>
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
`semlit.sh [-h] [-d `_delim_`] [-f `_fs_`] [-I `_dir_`] [-t `_tabstop_`] [`_sldocFiles_`]`

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

<pre>
mkdir html
cd html
perl ../semlit_pl.slsrc -I.. ../semlit.sldoc
cd ..
</pre>

This leaves all the output in the html subdirectory.

## SEMLIT Markup Commands

SEMLIT markup commands are embedded in the source files, both documentation and program.
They are of the general form:

`  `delim semlit fs command fs parameter [fs parameter ...] delim

By default, delim (delimiter) is '`=`' and fs (field separator) is '`,`' which
simplifies the general form to:

`  =semlit,`_command_`,`_parameter[_`,`_parameter...]=`

In the sections that follow, it is assumed that the delimiter and field separator
are defaulted.

A given command is normally included either in a documentation
source file (.sldoc) or a program master source file (.slsrc).  In the sections
that follow, they are indicated as "doc" or "src" respectively.

### tabstop - src

The tabstop command overrides the tabstop supplied on the command-line.  This
allows different source files to have different tab stop settings.

Form:

    =semlit,tabstop,columns=

Example:

    /* =semlit,tabstop,3= */

Since the tabstop semlit command is included in a program master source file,
it is common to enclose it in comments.  This allows the user to compile the
master program source file directly without generating a clean copy.

### srcfile - doc

The srcfile command identifies a program master source file and specifies its
output name.  The srcfile command must be specified exactly once for each
program master source file.  When the srcfile command is processed, it
causes the program master source file to be scanned, and the program output
source file to be created, as well as an html-formatted version of the
program output source file.  Finally, a link to the program output source file
is added to the documentation.  The author must be aware of this link and work
it into the documentation.

When naming the output file, it is common to use the proper file extension
for the language.  For example, if the program is written in C, the output
file would normally be named with the ".c" extension.  However, be aware that
web servers often expect certain files to be interpreted in special ways.  For
example, I originally had my program output file named "semlit.pl", but that
made it impossible for the viewer to download the program source; the web server
thought I wanted to execute the file.  The same thing happens with ".sh" and
".py" (for shell and python scripts).  So I settled on "semlit_pl.txt" and
"semlit_sh.txt", with the expectation that a user would rename it after download.

Form:

    =semlit,srcfile,inputfile,outputfile=

Example:
    The following program source files are documented.  Right-click the links and save.
    =semlit,srcfile,semlit_pl.slsrc,semlit_pl.txt= - main semlit Perl source code.
    =semlit,srcfile,semlit_sh.slsrc,semlit_sh.txt= - shell script wrapper.

### include - doc

The include command scans a documentation file.  One might have some
standardized boilerplate in a common directory (which might be specified
on the command-line using "-I directory").  Unlike the "srcfile" command,
"include" does not insert a link or anything else into the output documentation.

Form:

    =semlit,include,docfile=

Example:

    =semlit,include,copyright.sldoc=

block - src

The block command is used in the program source file to start a named block
of code.  The block is ended with the "endblock" command.  The code between
block and endblock can be inserted into the output documentation file using
the "insert" command.

Form:

    =semlit,block,blockname=
    ... program code ...
    =semlit,endblock,blockname=

Example:

    /* =semlit,block,mainloop= */
    for (i = 1; i < 10; ++i) {
        printf("i=%d\n", i);
    }
    /* =semlit,endblock,mainloop= */

It is also possible to have overlapping named blocks.  For example:

    /* =semlit,block,mainloop= */
    for (i = 1; i < 10; ++i) {
        /* =semlit,block,outputline= */
        printf("i=%d\n", i);
        /* =semlit,endblock,outputline= */
    }
    /* =semlit,endblock,mainloop= */

This allows one part of the document to give a general description of the
entire "mainloop", while another part of the document can describe in detail
the "outputline" section.

### endblock - src

The endblock command completes a named block of program source code.  See
"block" command above.

### insert - doc

The insert command inserts a named source code block into the output
documentation.  The named source code fragment is identified using
"block" and "endblock" commands in the program master source files.

Form:

    =semlit,insert,blockname=

Example:

    =semlit,insert,mainloop=

## Inspiration

Donald Knuth's 1984 paper "Literate Programming" describes a programming
language and documentation system called WEB.  Knuth states, "I chose the
name WEB partly because it was one of the few three-letter words of
English that hadn't already been applied to computers."  (Knuth had
named his system prior to the development of the Internet-based
"World-Wide Web" and the ubiquitous "web browser".)

One of the strong points of Literate Programming is that a program may
be described in the order in which it makes the most sense to teach it.
I.e. the ordering of the code does not have to match the execution order,
or the order that the compiler needs the code.  The WEB system takes care
of extracting the source code from the literate file and preparing it for
consumption by the compiler.

Another feature of the system is to introduce a very expressive programming
language which would be translated into the high-level language of the user's
choice.  The original WEB system produced Pascal code, but the WEB language
is not limited by the features supported by Pascal.  For example, whereas
Pascal has no macro-processing capability, the WEB system supports powerful
macros.  Note: a C translator has been added in the years since.

### Reasons for Lack of WEB Adoption

Why hasn't the software industry adopted WEB?  I believe that Literate
Programming is a brilliant idea, which can make programs and algorithms
much easier to write, read, and maintain.  So, why hasn't it caught on?
Based on my experience in the software industry I have a few theories.

In my experience, developers and technical managers do not place a great
deal of value on internal documentation.  It's hard enough to get
developers to document the high-level design; source comments, although
encouraged, are not valued highly-enough to justify a serious effort.

Why is source code documentation values so little?  Because of the
pressure to release a new product as soon as possible.  Due to the
perceived smallness of the market window, companies postpone as much
as possible until after the initial release.  Unfortunately, after the
initial release, there is pressure for the 1.1 release which fixes bugs
and adds necessary features.  And then more pressure for the 1.2 release.
The simple reality is that there is *never* time for anything seen as
"nice but not absolutely necessary".

Unfortunately, good quality source code documentation proves its value late
in the software cycle - during maintenance when the programmer looks at his
own code and wonders what he was smoking when he wrote it.  Or worse yet,
the original author as left for another company, and a different programmer,
unfamiliar with the code and frequently a less-experienced programmer, has
to add features or fix bugs.  This is when the value of high-quality
documentation becomes apparent, but at that point it's too late.

One more reason for resistance to WEB: learning curve.  It requires learning
a new programming language as well as the TeX typesetting markup language.
I find this barrier ironic since programmers have generally proven themselves
to be good at learning new things, but I have seen it time and time again.
I attribute the resistance to schedule pressures to produce, produce, produce.

### Why SEMLIT?

Given the reasons above, why did I develop SEMLIT?

First, I attempted to reduce the learning curve.  SEMLIT does not introduce
a new programming language.  Also, since the documentation is HTML, a variety
of WYSIWYG editors are available for writing the documentation.  This
document was written using the free SeaMonkey editor.  There is a small
number of SEMLIT-specific markups used to control the inclusion of code
fragments, but they are few and easily learned.

Second, I believe I have identified a situation where the value of source
code documentation is seen as much higher: API documentation.  Many APIs
are documented primarily in reference form, like man pages.  This is fine
and indeed is necessary to provide explicit descriptions of each API
function.  However, for sophisticated APIs, this omits an equally-important
form of documentation: how to use it.  It's one thing to understand what
each function does, but quite another to understand how they interrelate.
Very often, the best way to explain how to use an API is by example.

Example programs, if written simply and with the goal of teaching, can
demonstrate best practices for common use cases.  For this reason, example
programs are frequently included with API packages as learning aids.  In
many cases, they are as important as the reference material.

This is where I believe that a more-literate form of program documentation
will show its value.  A reader will benefit from the ability to mix prose
with code in a visually appealing way, in the order that a human should be
taught instead of the order that the compiler requires.  The fact that
SEMLIT extracts code fragments from the actual source file guarantees that
the code in the document is correct (assuming that the example programs are
tested).

### SEMLIT Drawbacks

All that said, there is still one fairly serious drawback to SEMLIT: the
master copy of the source file contains semlit markup, which makes it harder
to follow the code in the source file itself.  This is mitigated somewhat by
the fact that the browser should be used for reading the code.  I have found
it fairly easy to move between the browser and a text editor, but it does
take some getting used to.

Another drawback to SEMLIT as compared to Knuth's WEB system is that while
WEB has a single master file with both code and documentation, SEMLIT expects
the code and documentation to be stored in separate files.  This will almost
certainly lead to a greater frequency of code being modified without updates
being made to the documentation - out of sight, out of mind.
