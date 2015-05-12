#!/usr/local/bin/perl -w

# repeat the shebang for doc purposes (the real shebang needs to be line 1)
#!/usr/local/bin/perl -w

# semlit.pl - program to implement Steve Ford's "Semi-Literate Documentation".
# See http://wiki.geeky-boy.com/w/index.php?title=Sford_Semi-literate_documentation
#
# This code and its documentation is Copyright 2012, 2015 Steven Ford, http://geeky-boy.com
# and licensed "public domain" style under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any 
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/semlit/tree/gh-pages


use strict;
use English;  # allow long names for special variables
use Getopt::Long qw(:config no_ignore_case bundling);
use Text::Tabs;
use File::Basename;

# globals

my $tool = "semlit.pl";
my $usage_str = "$tool [-h] [-d delim] [-f fs] [-I dir] [-t tabstop] [files]";

my $main_doc_filename;
my $cur_file_name = "";
my $cur_file_linenum = 0;

my $doc_html_filename;
my $doc_html_outfd;

my $src_html_outfd;

my %srcblocks;  # lines of source named blocks
my %active_srcblocks;  # source blocks being added to at this moment
my %block_numrefs;  # number of doc references to each source block

my $exit_status = 0;  # assume success

# process command options and parameters

my $o_help;
my $o_fs = ",";
my $o_delim = "=";
my @o_incdirs = (".");  # GetOptions will append additional dirs for each "-I dir"
$tabstop = 4;  # defined and used by Text::Tabs - see "expand()" function

GetOptions("h"=> \$o_help, "d=s" => \$o_delim, "f=s" => \$o_fs, "I=s" => \@o_incdirs, "t=i" => \$tabstop) || usage("Error in GetOptions");
if (defined($o_help)) {
	help();  # if -h had a value, it would be in $opt_h
}

if (scalar(@ARGV) != 1) {
	usage("Error, .sldoc file missing");
}
$main_doc_filename = $ARGV[0];
if ( ! -r "$main_doc_filename" ) {
	usage("Error, could not read '$main_doc_filename'");
}

# open main doc file

$doc_html_filename = basename($main_doc_filename) . ".html";  # strip directory
open($doc_html_outfd, ">", $doc_html_filename) || die "Error, could not open htmlfile '$doc_html_filename'";

# Create frameset page

my $index_o_file;
open($index_o_file, ">", "index.html") || die "Error, could not open htmlfile 'index.html'";
print $index_o_file <<__EOF__;
<html><head></head>
<frameset cols="50%,*">
<frame src="$doc_html_filename" name="doc">
<frame src="blank.html" name="src">
</frameset>
</html>
__EOF__
close($index_o_file);

# Create blank page for initial source frame

my $blank_o_file;
open($blank_o_file, ">", "blank.html") || die "Error, could not open htmlfile 'blank.html'";
print $blank_o_file "<html><head></head><body>Click a source line number to see the line in context.</body></html>\n";
close($blank_o_file);

# Main loop; read each line in doc file

my $doc_html_str = process_doc_file($main_doc_filename);

# fix up multiple source references
foreach my $blockname (keys(%block_numrefs)) {
	if ($block_numrefs{$blockname} > 1) {
		# First ref points to next and last
		my $refnum = 1;
		my $this_block = $blockname . "_ref_" . ($refnum);
		my $first_block = $this_block;
		my $last_block = $blockname . "_ref_" . $block_numrefs{$blockname};
		my $next_block = $blockname . "_ref_" . ($refnum + 1);
		$doc_html_str =~ s/<\/pre><!-- endblock $this_block -->/<a href="#$next_block">next ref<\/a>  <a href="#$last_block">last ref<\/a><\/pre>/s;

		# Middle refs point to previous and next
		my $prev_block = $this_block;
		for ($refnum = 2; $refnum <= $block_numrefs{$blockname} - 1; $refnum ++) {
			# middle refs point to prev and next
			$this_block = $blockname . "_ref_" . ($refnum);
			$next_block = $blockname . "_ref_" . ($refnum + 1);
			$doc_html_str =~ s/<\/pre><!-- endblock $this_block -->/<a href="#$next_block">next ref<\/a>  <a href="#$prev_block">prev ref<\/a><\/pre>/s;
			$prev_block = $this_block;
		}

		# last ref points to first and previous
		$this_block = $blockname . "_ref_" . ($refnum);
		$doc_html_str =~ s/<\/pre><!-- endblock $this_block -->/<a href="#$first_block">first ref<\/a>  <a href="#$prev_block">prev ref<\/a><\/pre>/s;
	}
}

# write doc html file

print $doc_html_outfd "$doc_html_str\n";
close($doc_html_outfd);

# All done.
exit($exit_status);


# End of main program, start subroutines.


sub process_doc_file {
	my ($doc_filename) = @_;
	my $doc_infd;

	# open source file, using one or more search directories

	my $incdir;
	my $open_success = 0;
	foreach $incdir (@o_incdirs) {
		if (open($doc_infd, "<", "$incdir/$doc_filename")) {
			$open_success = 1;
			last;  # break out of foreach
		}
	}
	if (! $open_success) {
		err("could not open doc file '$doc_filename', skipping");
		return;
	}

	# Read entire file into memory

	my @doctexts = <$doc_infd>;
	close($doc_infd);
	chomp(@doctexts);  # remove line delims from every line
	my $num_lines = scalar(@doctexts);  # count lines in file
	my $doctext = join("\n", @doctexts) . "\n";  # combine as a single string
	$doctext =~ s/\r//gs;  # remove carriage returns, if any

	my ($save_doc_filename, $save_doc_linenum) = ($cur_file_name, $cur_file_linenum);
	($cur_file_name, $cur_file_linenum) = ($doc_filename, 0);

	# process semlit commands
	while ($doctext =~ /$o_delim\s*semlit\s*$o_fs\s*([^$o_delim]+)$o_delim/is) {
		my $cmd = $1;  # text of command (minus standard stuff)
		my $prefix = $PREMATCH;  # text preceiding the command
		my $suffix = $POSTMATCH;  # text after the command

		# calculate line number containing the start of this semlit command
		$cur_file_linenum = $num_lines - scalar(my @t = split("\n", $suffix)) + 1;

		my $repl = semlit_cmd($cmd);

		# Commands are removed, and often replaced with some result
		$doctext = $prefix . $repl . $suffix;
	}  # while

	($cur_file_name, $cur_file_linenum) = ($save_doc_filename, $save_doc_linenum);

	return $doctext;
}  # process_doc_file


# Parse and execute semlit command
sub semlit_cmd {
	my ($cmd) = @_;

	# semlit tabstop - doc: source tab expansion
	if ($cmd =~ /^tabstop\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
		if ($1 =~ /^\d+$/) {
			$tabstop = $1;  # used by Text::Tabs
			return "";
		} else {
			err("Tabstop value '$1' must be numeric");
			return "";
		}
	}

	# semlit srcfile - doc: read and process source file
	elsif ($cmd =~ /^srcfile\s*$o_fs\s*([^\s$o_fs]+)\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
		return process_src_file($1, $2);
	}

	# semlit include - doc: read and process doc file
	elsif ($cmd =~ /^include\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
		return process_doc_file($1);
	}

	# semlit insert - doc: insert a source block
	elsif ($cmd =~ /^insert\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
		my $block_name = $1;
		if (exists($srcblocks{$block_name})) {
			my $num_refs = 1;
			my $block_ref_name = $block_name;
			if (defined($block_numrefs{$block_name})) {
				$num_refs = $block_numrefs{$block_name} + 1;
				$block_ref_name = $block_name . "_ref_$num_refs";
			}
			$block_numrefs{$block_name} = $num_refs;

			my $block_str = $srcblocks{$block_name};
			return <<__EOF__;
<a name="$block_ref_name" id="$block_ref_name"><\/a>
<small><pre>
$block_str
<\/pre><!-- endblock $block_ref_name --></small>\n
__EOF__
		} else {
			err("attempt to insert block named '$block_name' but block not defined");
			return "";
		}
	}

	# semlit block - src: start a named block of source
	elsif ($cmd =~ /^block\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
		my $block_name = $1;
		if (defined($srcblocks{$block_name})) {
			err("block '$block_name' already defined");
			return "";
		}
		$srcblocks{$block_name} = "";
		$block_numrefs{$block_name} = 0;
		$active_srcblocks{$block_name} = $cur_file_linenum;
		print $src_html_outfd "<a name=\"$block_name\" id=\"$block_name\"><\/a>";
		return "";
	}

	# semlit endblock - src: end a named block of source
	elsif ($cmd =~ /^endblock\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
		my $block_name = $1;
		if (exists($active_srcblocks{$block_name})) {
			delete($active_srcblocks{$block_name});
			$srcblocks{$block_name} =~ s/\n$//s;
			return "";
		} else {
			err("found endblock for '$block_name', which is not active");
			return "";
		}
	}

	# semlit tooltip - create hover over text for a phrase
	elsif ($cmd =~ /^tooltip\s*$o_fs\s*([^\s$o_fs]+)\s*$o_fs\s*([^\s$o_fs]+)\s*$/i) {
                my $text_source = $1;
                my $text_link = $2;
                my $contents = file_get_contents($text_source);
                return <<__EOF__;
<a href="#" title="$contents" style="color:2222ee;border-bottom:1px dotted #2222ee;text-decoration: none;">$text_link</a>
__EOF__
        }


	# unrecognized semlit
	else {
		err("semlit command '$cmd' invalid or malformed");
		return "";
	}
}  # semlit_cmd


# process semlit srcfile command
sub process_src_file {
	my ($src_filename, $plain_src_filename) = @_;
	my $slsrc_infd;
	my $src_outfd;

	# open source file, using one or more search directories
	my $incdir;
	my $open_success = 0;
	foreach $incdir (@o_incdirs) {
		if (open($slsrc_infd, "<", "$incdir/$src_filename")) {
			$open_success = 1;
			last;  # break out of foreach
		}
	}
	if (! $open_success) {
		err("could not open src file '$src_filename', skipping");
		return "";
	}

	# create and write initial content to html-ified source file
	if (! open($src_html_outfd, ">", "$src_filename.html")) {
		err("could not open output source html file '$src_filename.html', skipping");
		close($slsrc_infd);
		return "";
	}
	print $src_html_outfd <<__EOF__;
<!DOCTYPE html><html><head><title>$plain_src_filename</title>
<link rel="stylesheet" href="//code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css">
<script src="//code.jquery.com/jquery-1.10.2.js"></script>
<script src="//code.jquery.com/ui/1.11.4/jquery-ui.js"></script>
<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/8.5/styles/default.min.css">
<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/8.5/highlight.min.js"></script>
<script>
  \$(function() {
    \$( document ).tooltip();
  });
</script>
<style>
#code {background-color:#ffffff;};
</style>
</head>
<body><h1>$plain_src_filename</h1>
<p><em>Hint:</em> do not cut-and-paste from this page.  Instead, right-click on '<a href=\"$plain_src_filename\">$plain_src_filename</a>' and save file.
<script>hljs.initHighlightingOnLoad();</script>
<small><pre><code id="code">
__EOF__

	# Create plaintext source file (without semlit commands)
	if (! open($src_outfd, ">", "$plain_src_filename")) {
		err("could not open output src '$plain_src_filename', skipping");
		close($slsrc_infd);
		close($src_html_outfd);
		return "";
	}

	my ($save_doc_filename, $save_doc_linenum) = ($cur_file_name, $cur_file_linenum);
	($cur_file_name, $cur_file_linenum) = ($src_filename, 0);
	my $src_linenum = 0;  # separate variable to track source output file

	my $iline;
	while (defined($iline = <$slsrc_infd>)) {
		chomp($iline);  # remove line delim
		$iline .= "\n";  # add newline
		$iline =~ s/\r//gs;  # remove carriage returns, if any
		$cur_file_linenum ++;

		# check for semlit commands
		if ($iline =~ /$o_delim\s*semlit\s*$o_fs\s*([^$o_delim]+)$o_delim/i) {
			semlit_cmd($1);
			# discard command line
		}
		else {
			$src_linenum ++;  # don't count semlit command lines

			print $src_outfd $iline;

			# fix up source for html rendering (tab expansion, special char encoding)
			$iline = expand($iline);  # expand tabs according to $tabstop.
			$iline =~ s/\&/\&amp;/g;  $iline =~ s/</\&lt;/g;  $iline =~ s/>/\&gt;/g;

			# if we are in at least one block, link the source to the earliest block's first doc reference
			if (scalar(keys(%active_srcblocks)) > 0) {
				# descending sort so that elemet 0 is largest
				my @active_blocks = sort { $active_srcblocks{$b} cmp $active_srcblocks{$a} } keys(%active_srcblocks);
				my $targ = $active_blocks[0] . "_ref_1";
				my $a = sprintf("<a href=\"$doc_html_filename#$targ\" target=\"doc\">%05d<\/a>  %s", $src_linenum, $iline);
				print $src_html_outfd $a;

				# for each open source block on this line of source, link the doc block to the that source block
				foreach my $block_name (keys(%active_srcblocks)) {
					my $a = sprintf("<a href=\"$cur_file_name.html#$block_name\" target=\"src\">%05d<\/a>  %s", $src_linenum, $iline);
					$srcblocks{$block_name} .= $a;
				}
			} else {
				# no active blocks
				print $src_html_outfd sprintf("%05d  %s", $src_linenum, $iline);
			}
		}
	}  # while

	close($slsrc_infd);
	close($src_outfd);

	print $src_html_outfd "</code></pre></small></body></html>\n";
	close($src_html_outfd);

	# if the source file started a block but reached eof without ending it, end it here.
	foreach (keys(%active_srcblocks)) {
		err("block named '$_' started but not ended");
		semlit_cmd("endblock$o_fs$_");  # end it for the user
	}

	# the semlit.srcfile command writes a link to the plaintext source file
	($cur_file_name, $cur_file_linenum) = ($save_doc_filename, $save_doc_linenum);
	return "<a href=\"$plain_src_filename\">$plain_src_filename</a>";
}  # process_src_file


sub err {
	my ($msg) = @_;

	print STDERR "Error [$cur_file_name:$cur_file_linenum], $msg\n";
	$exit_status ++;
}  # err


sub usage {
	my($err_str) = @_;

	if (defined $err_str) {
		print STDERR "$tool: $err_str\n\n";
	}
	print STDERR "Usage: $usage_str\n\n";
	$exit_status ++;
	exit($exit_status);
}  # usage

sub file_get_contents{
      my ($text_file) = @_;
      open FILE, $text_file or die $!;
      flock FILE, 1 or die $!; 		# wait for lock
      seek(FILE, 0, 0); 		# move pointer to beginning
      my $slurp = do{local $/; <FILE>};
      flock FILE, 8; 			# release the lock
      close(FILE);

      return $slurp;
} # file_get_contents

sub help {
	my($err_str) = @_;

	if (defined $err_str) {
		print "$tool: $err_str\n\n";
	}
	print <<__EOF__;
Usage: $usage_str
Where:
    -h - print help screen
    -d delim - delimiter character at start and end of a semlit command.
            (default to '=')
    -f fs - field separator character within a semlit command.
            (default to ',')
    -I dir - directory to find files for 'srcfile' and 'include' commands.
            (default to ".")  The "-I dir" option can be repeated.
    -t tabstop - convert tabs to "tabstop" spaces.
            (default to '4')
    files - zero or more input files.  If omitted, inputs from stdin.

__EOF__

	exit($exit_status);
}  # help
