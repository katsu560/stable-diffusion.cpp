#!/bin/sh

MYNAME=file1007.sh

TOPDIR=stable-diffusion.cpp
NAMEBASE=file

CMD=chk

###
msg()
{
	echo "$MYNAME: $*"
}

###
# diff old $1 $2 $OPT
diff_old()
{
	#msg "do_diff_old CMD:$CMD $1 $2 $3 $4  OPT:$OPT"
	# in $TOPDIR

	if [ ! x"$OPT" = x ]; then
		NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][0-9][0-9]\)/\2/'`
		#msg "diff: NEW:$NEWDATE"
		if [ ! x"$NEWDATE" = x"$OPT" ]; then
			msg "diff: skip $2 by $NEWDATE"
			return
		fi
	fi

	#msg "diff_old $1 $2"
	NEW="./$2"
	OLD=`find . -path './'$1'.[0-9][0-9][0-9][0-9]' | awk -v NEW="$NEW" '
	$0 != NEW { OLD=$0 }
	END   { print OLD }'`
	msg "diff -c $OLD $NEW"
	diff -c $OLD $NEW
}

# do_cp target origin modified
do_cp()
{
	#msg "do_cp CMD:$CMD $1 $2 $3 $4"

	FILES="$1 $2"
	if [ -f $3 ]; then
		FILES="$FILES $3"
	fi
	if [ $# = 4 ]; then
		if [ -f $4 ]; then
			FILES="$FILES $4"
		fi
	fi

	# check
	case $CMD in
	chk|check)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $1 ]; then
			msg "diff -c $2 $1"
			diff -c $2 $1
			#msg "RESULT: $RESULT $?"
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod|checkmod)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $3 ]; then
			msg "diff -c $1 $3"
			diff -c $1 $3
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod2|checkmod2)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "diff -c $1 $4"
				diff -c $1 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "diff -c $1 $3"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "diff -c $1 $3"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	chkmod12|checkmod12)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "diff -c $3 $4"
				diff -c $3 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "diff -c $2 $3"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "diff -c $2 $3"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	master)
		msg "cp -p $2 $1"
		cp -p $2 $1
		RESULT=`expr $RESULT + $?`
		;;
	mod)
		if [ -f $3 ]; then
			msg "cp -p $3 $1"
			cp -p $3 $1
			RESULT=`expr $RESULT + $?`
		fi
		;;
	mod2)
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "cp -p $4 $1"
				cp -p $4 $1
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "cp -p $3 $1"
				cp -p $3 $1
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "cp -p $3 $1"
				cp -p $3 $1
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	diff)
		diff_old $1 $2
		;;
	*)	msg "unknown command: $CMD"
		;;
	esac
}

do_mk()
{
	msg "making new $NAMEBASE script $NAMEBASE$DT1.sh and copy backup files ..."

#do_cp ggml.c		  ggml.c.0420		  ggml.c.0420mod    ggml.c.0420mod2
#do_cp examples/CMakeLists.txt examples/CMakeLists.txt.0413 examples/CMakeLists.txt.0415mod
	cat $MYNAME | awk -v DT0=$DT0 -v DT1=$DT1 -v TOP="$TOPDIR" '
	function exists(file) {
		n=(getline _ < file);
		if (n > 0) {
			return 1; # found
		} else if (n == 0) {
			return 1; # empty
		} else {
			return 0; # error
		}
		return 0; # error
	}
	function update(L) {
		NARG=split(L, ARG, /[ \t]/);
		TOPFILE=TOP "/" ARG[2]
		TOPFILEDT1=TOP "/" ARG[2] "." DT1
		if (exists(TOPFILE)==0) { printf "# %s\n",L; return 1; }
		CMD="date '+%m%d' -r " TOPFILE;
		CMD | getline; DT=$0;
		TOPFILEDT=TOP "/" ARG[2] "." DT
		printf "do_cp %s\t%s.%s\t%s.%smod\n",ARG[2],ARG[2],DT,ARG[2],DT1;
		if (exists(TOPFILEDT)==1) { printf "# %s skip cp\n",TOPFILEDT; return 0; }
		if (DT==DT1) { CMD="cp -p " TOPFILE " " TOPFILEDT1; print CMD > stderr; system(CMD); }
		return 0;
	}
	BEGIN		{ stderr="/dev/stderr"; st=1 }
	st==1 && /^MYNAME=/	{ L=$0; sub(DT0, DT1, L); print L; st=2; next }
	st==2 && /^usage/	{ L=$0; print L; st=3; next }
	st==3 && /^do_cp /	{ L=$0; update(L); next }
	st==3			{ L=$0; gsub(DT0, DT1, L); print L; next }
				{ L=$0; print L; next }
	' - > $NAMEBASE$DT1.sh

	msg "$NAMEBASE$DT1.sh created"
}

usage()
{
	echo "usage: $MYNAME [-h] chk|chkmod|chkmod2|checkmod12|master|mod|mod2|diff|mk|new [DT]"
	echo "-h ... this help message"
	echo "chk ... diff master"
	echo "chkmod ... diff mod"
	echo "chkmod2 ... diff mod2"
	echo "chkmod12 ... diff mod mod2"
	echo "master ... cp master files on 1007"
	echo "mod ... cp mod files on 1007"
	echo "mod2 ... cp mod2 files on 1007"
	echo "diff [DT] ... diff old and new, new on DT only if set DT"
	echo "mk [DT] ... create new shell script"
	echo "new [DT] ... show new files since DT"
}

###
if [ x"$1" = x -o x"$1" = "x-h" ]; then
	usage
	exit 1
fi
ORGCMD="$1"
CMD="$1"
OPT="$2"
msg "CMD: $CMD"
msg "OPT: $OPT"

if [ $CMD = "mk" ]; then
	DT0=`echo $MYNAME | sed -e 's/'$NAMEBASE'//' -e 's/.sh//'`
	DT1=`date '+%m%d'`
	# overwrite
	if [ ! x"$OPT" = x ]; then
		DT1="$OPT"
	fi
	msg "DT0: $DT0  DT1: $DT1"
	do_mk $DT0 $DT1
	exit 0
fi
if [ $CMD = "new" ]; then
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt.1001
	#-rw-r--r-- 1 user user 5898 Oct  1 04:40 ggml/README.md
	DT1=`date '+%m%d'`
	#NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][0-9][0-9]\)/\2/'`
	#find $TOPDIR -type f -mtime 0 -exec ls -l '{}' \; | awk -v DT1=$DT1 '
	find $TOPDIR -type f -mtime 0 | awk -v DT1=$DT1 '
	BEGIN { PREV="" }
	#{ print "line: ",$0; }
	#{ ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	#END { ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	{ ADDDT=PREV "." DT1; if (ADDDT==$0) { PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	END { ADDDT=PREV "." DT1; if (ADDDT==$0) { ; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	' -
	exit 0
fi


###
if [ ! -d $TOPDIR ]; then
	msg "no $TOPDIR, exit"
	exit 3
fi
cd $TOPDIR

msg "git branch"
git branch

# check:  ls -l target origin modified
# revert: cp -p origin target
# revise: cp -p modifid target
#
# do_cp target origin(master) modified(gq)
RESULT=0
do_cp CMakeLists.txt	CMakeLists.txt.0825	CMakeLists.txt.1007mod
# stable-diffusion.cpp/CMakeLists.txt.0825 skip cp
# do_cp main.cpp	main.cpp.0815	main.cpp.0815mod
# do_cp stb_image_write.h	stb_image_write.h.0815	stb_image_write.h.0815mod
do_cp stable-diffusion.cpp	stable-diffusion.cpp.1007	stable-diffusion.cpp.1007mod
do_cp stable-diffusion.h	stable-diffusion.h.1007	stable-diffusion.h.1007mod
do_cp examples/CMakeLists.txt	examples/CMakeLists.txt.0819	examples/CMakeLists.txt.1007mod
# stable-diffusion.cpp/examples/CMakeLists.txt.0819 skip cp
do_cp examples/main.cpp	examples/main.cpp.1007	examples/main.cpp.1007mod
do_cp examples/stb_image.h	examples/stb_image.h.0819	examples/stb_image.h.1007mod
# stable-diffusion.cpp/examples/stb_image.h.0819 skip cp
do_cp examples/stb_image_write.h	examples/stb_image_write.h.1007	examples/stb_image_write.h.1007mod
do_cp ggml/src/ggml.c	ggml/src/ggml.c.1007	ggml/src/ggml.c.1007mod
do_cp ggml/include/ggml/ggml.h	ggml/include/ggml/ggml.h.1007	ggml/include/ggml/ggml.h.1007mod
msg "RESULT: $RESULT"

if [ $CMD = "chk" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for zipping, syncing"
	else
		msg "do $MYNAME chkmod and $MYNAME master before zipping, syncing"
	fi
fi
if [ $CMD = "chkmod" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		msg "save files and update $MYNAME"
	fi
fi
if [ $CMD = "chkmod2" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		msg "save files and update $MYNAME"
	fi
fi

# cmake .. -DGGML_OPENBLAS=ON
# make test-blas0 test-grad0 test-mul-mat0 test-mul-mat2 test-svd0 test-vec0 test-vec1 test0 test1 test2 test3
# GGML_NLOOP=1 GGML_NTHREADS=4 make test
msg "end"
