#!/bin/sh
# bld.sh - build this tool
# This code and its documentation is Copyright 2012, 2015 Steven Ford, http://geeky-boy.com
# and licensed "public domain" style under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/semlit/tree/gh-pages

rm -rf html bin
mkdir html
mkdir bin

cd html
rm -f semlit_pl.txt semlit.txt *.html
# The semlit program enclosed the semlit markup in coments, so it can be executed directly.
if perl ../semlit_pl.slsrc -I..  ../semlit.sldoc; then :
	cp semlit_pl.txt ../bin/semlit.pl
	cp semlit_sh.txt ../bin/semlit.sh
	chmod +x ../bin/*

	# Make sure that the output of semlit can execute cleanly.
	if ../bin/semlit.sh -I..  ../semlit.sldoc; then :
	else :
		echo "Error running processed semlit_pl.txt"
		exit 1
	fi

	# Remove execute permission so web servers don't refuse to serve it.
	chmod -x semlit_pl.txt semlit_sh.txt
else :
	echo "Error running semlit.slsrc"
	exit 1
fi
cd ..
