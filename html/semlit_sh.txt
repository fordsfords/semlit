#!/bin/sh

# repeat the shebang for doc purposes (the real shebang needs to be line 1)
#!/bin/sh

# semlit - wrapper script around the perl tool

IWD=`pwd`                    # remember initial working directory

# Find dir where tool is stored (useful for finding related files)
TOOLDIR=`dirname $0`
# Make sure TOOLDIR is a full path name (not relative)
cd $TOOLDIR; TOOLDIR=`pwd`; cd $IWD

perl $TOOLDIR/semlit.pl $*
exit $?
