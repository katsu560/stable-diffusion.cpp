#!/bin/sh

# zip ggml stable-diffusion.cpp files
# exclude:
# ggml/models/gpt-2-117M/ggml-model.bin and others in MODELS
#zip -rv ggml-230218.zip ggml

MYNAME="mkzip-sdcpp.sh"

TOPDIR=stable-diffusion.cpp

BUILDPATH="$TOPDIR/build"

MODELSPATH1="$TOPDIR/models"
MODELSPATH2="$BUILDPATH/models"
MODELS=""

DATEFOLDERS=""


# flags
EXMODEL=0
EXDATE=0
ADDFOLDER=0
ADDFOLDEROPT=""


###
msg()
{
	echo "$MYNAME: $*"
}


###
usage()
{
	echo "usage: $MYNAME [-h][-xm][-xd][-a folders,...] zip-filename"
	echo "  -h ... this message"
	echo "  -xm ... exclude models in $MODELSPATH1,$MODELSPATH2"
	echo "  -xd ... exclude date folders in build folder, except for below id"
	echo "  -a 0218,0226up ... add specified folders in build folder"
	echo "  chkmodels ... check models"
	echo "  chkdate ... check date folders"
	echo "  zip-filename ... zip filename ex. ggml-230218.zip"
}

# set MODELS
do_checkmodels()
{
	msg "# checkmodels"
	# ex. ggml/build/models/whisper/ggml-small.bin
	if [ -d $MODELSPATH1 ]; then
		msg "find -L $MODELSPATH1"
		find -L $MODELSPATH1
		MODELS1=`find -L $MODELSPATH1 -type f | awk '{ printf(" %s",$0); }'`
		msg "MODELS1: $MODELS1"
	fi
	if [ -d $MODELSPATH2 ]; then
		msg "find -L $MODELSPATH2"
		find -L $MODELSPATH2
		MODELS2=`find -L $MODELSPATH2 -type f | awk '{ printf(" %s",$0); }'`
		msg "MODELS2: $MODELS2"
	fi

	MODELS="$MODELS1 $MODELS2"
}

do_checkdatefolders()
{
	msg "# checkdatefolders"
	# ex. ggml/build/0226up
	if [ -d $BUILDPATH ]; then
		msg "find -L $BUILDPATH"
		#find -L $BUILDPATH
		DATEFOLDERS=`find -L $BUILDPATH -type d | \
		awk '/build.[0-9]{4}[[:print:]]*/ { print $0 }'`
		msg "DATEFOLDERS: $DATEFOLDERS"
	fi
}


###
# options
if [ $# = 0 ]; then
	usage
	exit 1 
fi

# save options
ALLOPT="$*"

while [ ! x"$1" = x ];
do
	#msg "OPT: $1"
	case "$1" in
		-h) usage; exit 1;;
		-xm) EXMODEL=1;;
		-xd) EXDATE=1;;
		-a) ADDFOLDER=1; shift; ADDFOLDEROPT=$1;;
		-*) msg "# ignore unknown option: $1";;
		*) break;;
	esac
	shift
done

# check
if [ ! -d $TOPDIR ]; then
	msg "# can't find $TOPDIR, exit"
	exit 2
fi

ZIPFILE="$1"
if [ -e $ZIPFILE ]; then
	msg "# already existed: $ZIPFILE"
	exit 3
fi

# do ckeck models
if [ x"$1" = xchkmodels ]; then
	msg "# do check models"
	do_checkmodels
	exit 4
fi

# do ckeck date folders
if [ x"$1" = xchkdate ]; then
	msg "# do check date folders"
	do_checkdatefolders
	exit 5
fi

# add folders
ADDOPT=""
if [ $ADDFOLDER = 1 ]; then
	msg "# add folders: $ADDFOLDEROPT"
	ADDFOLDEROPTS=`echo $ADDFOLDEROPT | sed 's/,/ /g'`
	for i in $ADDFOLDEROPTS
	do
		msg "# add folders: $i"
		if [ -e $BUILDPATH/$i ]; then
			ADDOPT="$ADDOPT $BUILDPATH/$i"
		fi
	done
fi

# delete CMakeFiles
if [ -d $BUILDPATH/CMakeFiles ]; then
	msg "# no rm -rf $BUILDPATH/CMakeFiles"
	#msg "rm -rf $BUILDPATH/CMakeFiles"
	#rm -rf $BUILDPATH/CMakeFiles
fi

# exclude models
XOPT=""
if [ $EXMODEL = 1 ]; then
	do_checkmodels
	for i in $MODELS
	do
		XOPT="$XOPT -x $i"
	done
	msg "# exclude models"
fi
# exclude date folders
if [ $EXDATE = 1 ]; then
	do_checkdatefolders
	for i in $DATEFOLDERS
	do
		XOPT="$XOPT -x $i/*"
	done
	msg "# exclude date folders"
fi

# do zip
msg "zip -rvy $ZIPFILE $TOPDIR $XOPT"
zip -rvy $ZIPFILE $TOPDIR $XOPT

if [ $ADDFOLDER = 1 ]; then
	msg "zip -rvy $ZIPFILE $ADDOPT"
	zip -rvy $ZIPFILE $ADDOPT
fi

msg "# finished"

msg "$ $MYNAME $ALLOPT"
msg "ls -l $ZIPFILE"
ls -l $ZIPFILE
# end

