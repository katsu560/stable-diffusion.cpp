#!/bin/sh

# update katsu560/stable-diffusion.cpp
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYNAME=update-katsu560-sdcpp.sh

REMOTEURL=https://github.com/katsu560/stable-diffusion.cpp
TOPDIR=stable-diffusion.cpp
BUILDPATH="$TOPDIR/build"

BLASCMKLIST="$TOPDIR/ggml/CMakeLists.txt"
OPENBLAS=`grep -sr GGML_OPENBLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*GGML_OPENBLAS.*/GGML_OPENBLAS/'`
BLAS=`grep -sr GGML_BLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*GGML_BLAS.*/GGML_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
        # CMakeLists.txt w/ GGML_OPENBLAS
        GGML_OPENBLAS="GGML_OPENBLAS"
        BLASVENDOR=""
        echo "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
if [ ! x"$BLAS" = x ]; then
        # CMakeLists.txt w/ GGML_BLAS
        GGML_OPENBLAS="GGML_BLAS"
        BLASVENDOR="-DGGML_BLAS_VENDOR=OpenBLAS"
        echo "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi

if [ ! x"$GGML_OPENBLAS" = x ]; then
	BLASOPT="-D$GGML_OPENBLAS=ON $BLASVENDOR"
else
	BLASOPT=""
fi
TESTOPT="-DGGML_BUILD_TESTS=OFF"
EXOPT="-DGGML_BUILD_EXAMPLES=OFF"

#CMKOPT=
CMKOPTNOAVX="-DGGML_AVX=OFF -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=OFF $BLASOPT $TESTOPT $EXOPT"
CMKOPTAVX="-DGGML_AVX=ON -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=ON $BLASOPT $TESTOPT $EXOPT"
CMKOPTAVX2="-DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=ON -DGGML_F16C=ON $BLASOPT $TESTOPT $EXOPT"
#
CMKOPTNONE="$BLASOPT $TESTOPT $EXOPT"
CMKOPT="$CMKOPTNONE"

TESTOPT="GGML_NLOOP=1 GGML_NTHREADS=4"
TESTS=""
#TESTS="test-grad0 test-mul-mat0 test-mul-mat2 test-svd0 test-vec0 test-vec1 test0 test1 test2 test3"
#TESTSCPP="test-opt test-quantize-fns test-quantize-perf test-pool test-customop test-conv-transpose test-rel-pos test-xpos"
#NOTEST="test-blas0"
for i in $TESTSCPP
do
        if [ -e $TOPDIR/tests/$i.cpp ]; then
                TEST=`basename $i`
                TESTS="$TESTS $TEST"
        fi
        if [ -e $TOPDIR/tests/$i.c ]; then
                TEST=`basename $i`
                TESTS="$TESTS $TEST"
        fi
done

ALLBINS="sd"

MKCLEAN=0
NODIE=0
NOCLEAN=0
NOCOPY=0
SEEDOPT=

PROMPTAST="a photograph of an astronaut riding a horse"
#PROMPTGIRL="Girl posing for photo in white bra and tight denim skirt, full head, full body, face, with cropped t-shirt, bra, slim figure, smaller bust, long legs, white sneakers, slim girl model, 24 year old female model,"
PROMPTGIRL="Girl posing for photo in white bra and tight denim skirt, full head, full body, wide shot, with cropped t-shirt, bra, slim figure, smaller bust, long legs, white sneakers, slim girl model, 24 year old female model,"
SDOPT="-H 768"
#SEED=1685215400
SEED=685215400

###
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
ESC=$(printf '\033')
ESCBLACK="${ESC}[30m"
ESCRED="${ESC}[31m"
ESCGREEN="${ESC}[32m"
ESCYELLOW="${ESC}[33m"
ESCBLUE="${ESC}[34m"
ESCMAGENTA="${ESC}[35m"
ESCCYAN="${ESC}[36m"
ESCWHITEL="${ESC}[37m"
ESCDEFAULT="${ESC}[38m"
ESCBACK="${ESC}[m"
ESCRESET="${ESC}[0m"

msg()
{
	echo "$MYNAME: $*" 1>&2
}

die()
{
	CODE=$1
	shift
	msg "$*"
	if [ $NODIE = 0 ]; then
		exit $CODE
	fi
}

chk_and_cp()
{
	#msg "chk_and_cp: nargs:$# args:$*"
        chkfiles="$*"
        if [ x"$chkfiles" = x ]; then
                msg "chk_and_cp: no cpopt"
                return 1
        fi

	# get cp opt
        cpopt=$1
        shift
	#msg "chk_and_cp: n:$# args:$*"

        chkfiles="$*"
	ncp=$#
	dstdir=
	if [ $# -ge 2 ]; then
		dstdir=`eval echo '$'$#`
		if [ ! -d $dstdir ]; then
			dstdir=
		fi
	fi
	#msg "chk_and_cp: cpopt:$cpopt ncp:$ncp chkfiles:$chkfiles dstdir:$dstdir"

        cpfiles=
        for i in $chkfiles
        do
		#msg "chk_and_cp: ncp:$ncp i:$i"
		if [ $ncp -le 1 ]; then
			break
		fi

		if [ -f $i ]; then
			cpfiles="$cpfiles $i"
		elif [ -d $i -a ! "x$i" = x"$dstdir" ]; then
			cpfiles="$cpfiles $i"
		fi
	
		ncp=`expr $ncp - 1`
	done

	#msg "chk_and_cp: cpopt:$cpopt ncp:$ncp cpfiles:$cpfiles dstdir:$dstdir"
	if [ x"$cpfiles" = x ]; then
		msg "chk_and_cp: no cpfiles"
		return 2
	fi

	if [ x"$dstdir" = x ]; then
		msg "chk_and_cp: no dstdir"
		return 3
	elif [ ! -d $dstdir ]; then
		msg "chk_and_cp: not dir"
		return 4
	fi

        msg "cp $cpopt $cpfiles $dstdir"
        cp $cpopt $cpfiles $dstdir || return 2

        return 0
}

# chk_and_cp test code
func_test()
{
	RETCODE=$?

	OKCODE=$1
	shift
	TESTMSG="$*"

	if [ $RETCODE -eq $OKCODE ]; then
		msg "ret:$RETCODE expected:$OKCODE $TESTMSG"
	else
		msg "ret:$RETCODE expected:$OKCODE $ESCRED$TESTMSG$ESCBACK"
	fi
}

test_chk_and_cp()
{
	# test files and dir, test-0.$$, testdir-0.$$: not existed
	touch test.$$ test-1.$$ test-2.$$
	mkdir testdir.$$
	ls -ld test.$$ test-1.$$ test-2.$$ testdir.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ testdir.$$"

	# test code
	chk_and_cp
	func_test 1 "no cpopt: chk_and_cp"

	chk_and_cp -p
	func_test 2 "no cpfiles: chk_and_cp -p"

	chk_and_cp -p test-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$"
	chk_and_cp -p test.$$
	func_test 2 "no cpfiles: chk_and_cp -p test.$$"
	chk_and_cp -p testdir-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p testdir-0.$$"
	chk_and_cp -p testdir.$$
	func_test 2 "no cpfiles: chk_and_cp -p testdir.$$"

	chk_and_cp -p test-0.$$ test-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ test-0.$$"
	chk_and_cp -p test-0.$$ test.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ test.$$"
	chk_and_cp -p test-0.$$ testdir-0.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ testdir-0.$$"
	chk_and_cp -p test-0.$$ testdir.$$
	func_test 2 "no cpfiles: chk_and_cp -p test-0.$$ testdir.$$"

	chk_and_cp -p test.$$ test-0.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ test-0.$$"
	chk_and_cp -p test.$$ test.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ test.$$"
	chk_and_cp -p test.$$ test-1.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ test-1.$$"
	chk_and_cp -p test.$$ testdir-0.$$
	func_test 3 "no dstdir: chk_and_cp -p test.$$ testdir-0.$$"
	chk_and_cp -p test.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-0.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test-0.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test-1.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir-0.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ testdir-0.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ testdir.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$
	func_test 0 "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$"
	msg "ls testdir.$$"; ls testdir.$$; rm -rf testdir.$$; mkdir testdir.$$


	rm test.$$ test-1.$$ test-2.$$
	rm -rf testdir.$$
	ls -ld test.$$ test-1.$$ test-2.$$ testdir.$$
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ testdir.$$"
}
#msg "test_chk_and_cp"; test_chk_and_cp; exit 0

usage()
{
	echo "usage: $MYNAME [-h][-nd][-nc][-noavx|avx|avx2] dirname branch cmd"
	echo "options: (default)"
	echo "  -h|--help ... this message"
	echo "  -nd|--nodie ... no die"
	echo "  -nc|--noclean ... no make clean"
	#echo "  -up ... upstream, no mod source, skip test-blas0"
	echo "  -noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2 (AVX)"
	echo "  -s|--seed SEED ... set SEED"
	echo "  dirname ... directory name ex. 0226up"
	echo "  branch ... git branch ex. master, gq, devpr"
	echo "  cmd ... sycpcmktstmaex sy/sync,cp/copy,cmk/cmake,tst/test,ex/examples,ma/main"
	echo "  cmd ... noexmaonly noex .. build examples but no exec, maonly .. exec main only"
	echo "  cmd ... sd14|sd14only sdnano|sdnanoonly"
}

###
if [ x"$1" = x -o $# -lt 3 ]; then
	usage
	exit 1
fi

ALLOPT="$*"
OPTLOOP=1
while [ $OPTLOOP -eq 1 ];
do
	case $1 in
	-h|--help) usage; exit 1;;
	-nd|--nodie) NODIE=1;;
	-nc|--noclean) NOCLEAN=1;;
	-ncp|--nocopy) NOCOPY=1;;
	-up)	ALLBINS="$ALLBINSUP";;
	-noavx)	CMKOPT="$CMKOPTNOAVX";;
	-avx)	CMKOPT="$CMKOPTAVX";;
	-avx2)	CMKOPT="$CMKOPTAVX2";;
	-s|-seed) shift; SEEDOPT=$1;;
	*)	OPTLOOP=0; break;;
	esac
	shift
done

DIRNAME="$1"
BRANCH="$2"
CMD="$3"

###
do_sync()
{
	msg "# synchronizing ..."
        msg "git branch"
        git branch
        msg "git checkout $BRANCH"
        git checkout $BRANCH
        msg "git fetch"
        git fetch
        msg "git reset --hard origin/master"
        git reset --hard origin/master
}

do_cp()
{
	# in build

	msg "# copying ..."
	chk_and_cp -p ../CMakeLists.txt $DIRNAME|| die 21 "can't copy files"
	chk_and_cp -p ../main.cpp ../stable-diffusion.cpp ../stable-diffusion.h ../rng.h ../rng-philox.h $DIRNAME || die 22 "can't copy src files"
	chk_and_cp -pr ../examples $DIRNAME || die 23 "can't copy src files"
	msg "find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;"
	find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;
	# $ ls -l ggml/build/0521up/examples/mnist/models/mnist/
	#-rw-r--r-- 1 user user 1591571 May 21 22:45 mnist_model.state_dict
	#-rw-r--r-- 1 user user 7840016 May 21 22:45 t10k-images.idx3-ubyte
        #msg "rm -r $DIRNAME/ggml/examples/mnist/models"
        #rm -r $DIRNAME/ggml/examples/mnist/models
}

do_cmk()
{
	# in build

	msg "# do cmake"
	if [ -f CMakeCache.txt ]; then
		msg "rm CMakeCache.txt"
		rm CMakeCache.txt
	fi
	msg "cmake .. $CMKOPT"
	cmake .. $CMKOPT || die 31 "cmake failed"
	msg "cp -p Makefile $DIRNAME/Makefile.build"
	cp -p Makefile $DIRNAME/Makefile.build
}

do_test()
{
	msg "# testing ..."
	if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
		MKCLEAN=1
		msg "make clean"
		make clean || die 41 "make clean failed"
	fi
	msg "make $TESTS"
	make $TESTS || die 42 "make test build failed"
	msg "env $TESTOPT make test"
	env $TESTOPT make test || die 43 "make test failed"
	msg "mv bin/test* $DIRNAME/"
	mv bin/test* $DIRNAME || die 44 "can't move tests"
}

get_newnum()
{
	if [ x"$1" = x ]; then
		msg "get_newnum: need base name"
		return 1
	fi

	N=0
	while [ -f $1-$N.png ];
	do
		N=`expr $N + 1`
	done

	echo "$1-$N.png"
	return 0
}

do_examples()
{
	EXOPT="$1"

	msg "# executing examples ..."
	# make
	if [ ! x"$EXOPT" = xNOMAKE ]; then
		if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
			MKCLEAN=1
			msg "make clean"
			make clean || die 51 "make clean failed"
		fi
		msg "make $ALLEX"
		make $ALLEX || die 52 "make $ALLEX failed"
		EXBIN=""; for i in $ALLEX ;do EXBIN="$EXBIN bin/$i" ;done
		msg "cp -p $EXBIN $DIRNAME/"
		cp -p $EXBIN $DIRNAME || die 53 "can't cp $EXBIN"
	fi

	# exec
	PROMPTEX="This is an example"
        PROMPT="tell me about creating web site in 5 steps:"
	JFKWAV=jfk.wav
	NHKWAV=nhk0521-16000hz1ch-0-10s.wav
	SEED=1685215400

	EXMODELS="../../../ggml/ggml/build/models"

	if [ ! x"$EXOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/gpt-2 ]; then
			msg "./$DIRNAME/gpt-2 -m $EXMODELS/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
			./$DIRNAME/gpt-2 -m $EXMODELS/gpt-2-117M/ggml-model-f32.bin -s $SEED -p "$PROMPTEX" || die 64 "do gpt-2 failed"
		fi

		if [ -f ./$DIRNAME/gpt-j ]; then
			msg "./$DIRNAME/gpt-j -m $EXMODELS/gpt-j-6B/ggml-model-f16.bin -s $SEED -p \"$PROMPT\""
			./$DIRNAME/gpt-j -m $EXMODELS/gpt-j-6B/ggml-model-f16.bin -s $SEED -p "$PROMPT" || die 74 "do gpt-j failed"
		fi

		if [ -f ./$DIRNAME/whisper ]; then
			msg "./$DIRNAME/whisper -l en -m $EXMODELS/whisper/ggml-base.bin -f $JFKWAV"
			./$DIRNAME/whisper -l en -m $EXMODELS/whisper/ggml-base.bin -f $JFKWAV || die 84 "do whisper failed"
			msg "./$DIRNAME/whisper -l ja -m $EXMODELS/whisper/ggml-small.bin -f $NHKWAV"
			./$DIRNAME/whisper -l ja -m $EXMODELS/whisper/ggml-small.bin -f $NHKWAV || die 85 "do whisper failed"
		fi

		if [ -f ./$DIRNAME/gpt-neox ]; then
                        msg "./$DIRNAME/gpt-neox -m $EXMODELS/gpt-neox/ggml-3b-f16.bin -s $SEED -p \"$PROMPT\""
                        ./$DIRNAME/gpt-neox -m $EXMODELS/gpt-neox/ggml-3b-f16.bin -s $SEED -p "$PROMPT" || die 91 "do gpt-neox failed"

                        msg "./$DIRNAME/gpt-neox -m $EXMODELS/cyberagent/ggml-model-calm-large-f16.bin -s $SEED -p \"$PROMPT\""
                        ./$DIRNAME/gpt-neox -m $EXMODELS/cyberagent/ggml-model-calm-large-f16.bin -s $SEED -p "$PROMPT" || die 101 "do gpt-neox calm failed"
                        msg "./$DIRNAME/gpt-neox -m $EXMODELS/cyberagent/ggml-model-calm-3b-q4_0.bin -s $SEED -p \"$PROMPT\""
                        ./$DIRNAME/gpt-neox -m $EXMODELS/cyberagent/ggml-model-calm-3b_q4_0.bin -s $SEED -p "$PROMPT" || die 102 "do gpt-neox calm failed"
		fi
	fi
}

do_sdv14()
{
	MAOPT="$1"

	# make
	if [ ! x"$MAOPT" = xNOMAKE ]; then
		if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
			MKCLEAN=1
			msg "make clean"
			make clean || die 61 "make clean failed"
		fi
		msg "make $ALLBINS"
		make $ALLBINS || die 52 "make $ALLBINS failed"
		BINS=""; for i in $ALLBINS ;do BINS="$BINS bin/$i" ;done
		msg "cp -p $BINS $DIRNAME/"
		cp -p $BINS $DIRNAME || die 53 "can't cp $BINS"
	fi

	if [ ! x"$SEEDOPT" = x ]; then
		SEED=$SEEDOPT
	fi

	DT=`date '+%m%d'`

	if [ ! x"$MAOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/sd ]; then
			TYPE=f16
			OUTBASE="girl-$TYPE-$DT-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 61 "do sd failed"

			TYPE=q4_0
			OUTBASE="girl-$TYPE-$DT-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 62 "do sd failed"

			TYPE=q5_0
			OUTBASE="girl-$TYPE-$DT-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 64 "do sd failed"

			TYPE=q8_0
			OUTBASE="girl-$TYPE-$DT-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sdv14-ggml-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 66 "do sd failed"
		else
			msg "${ESCRED}no ./$DIRNAME/sd"
		fi
	fi

}

do_sdnano()
{
	MAOPT="$1"

	# make
	if [ ! x"$MAOPT" = xNOMAKE ]; then
		if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
			MKCLEAN=1
			msg "make clean"
			make clean || die 61 "make clean failed"
		fi
		msg "make $ALLBINS"
		make $ALLBINS || die 52 "make $ALLBINS failed"
		BINS=""; for i in $ALLBINS ;do BINS="$BINS bin/$i" ;done
		msg "cp -p $BINS $DIRNAME/"
		cp -p $BINS $DIRNAME || die 53 "can't cp $BINS"
	fi

	if [ ! x"$SEEDOPT" = x ]; then
		SEED=$SEEDOPT
	fi

	DT=`date '+%m%d'`

	if [ ! x"$MAOPT" = xNOEXEC ]; then
		if [ -f ./$DIRNAME/sd ]; then
			# sd-nano
			SDOPT0="$SDOPT"
			SDOPT="-W 128 -H 128"

			TYPE=f16
			OUTBASE="girl-$TYPE-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sd-nano-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sd-nano-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 74 "do sd failed"

			TYPE=f16
			OUTBASE="girl-$TYPE-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sd-nano-2-1-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sd-nano-2-1-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 84 "do sd failed"
			TYPE=q4_0
			OUTBASE="girl-$TYPE-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sd-nano-2-1-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sd-nano-2-1-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 86 "do sd failed"
			TYPE=q8_0
			OUTBASE="girl-$TYPE-$SEED"
			OUT=`get_newnum $OUTBASE`
			msg "./$DIRNAME/sd -m ../models/sd-nano-2-1-$TYPE.bin $SDOPT -s $SEED -p \"$PROMPTGIRL\" -o $OUT"
			./$DIRNAME/sd -m ../models/sd-nano-2-1-$TYPE.bin $SDOPT -s $SEED -p "$PROMPTGIRL" -o $OUT  || die 88 "do sd failed"

			SDOPT="$SDOPT0"
			SDOPT0=
		else
			msg "${ESCRED}no ./$DIRNAME/sd"
		fi
	fi

}

do_main()
{
	MAOPT="$1"

	msg "# executing main ..."
	# make
	if [ ! x"$MAOPT" = xNOMAKE ]; then
		if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
			MKCLEAN=1
			msg "make clean"
			make clean || die 61 "make clean failed"
		fi
		msg "make $ALLBINS"
		make $ALLBINS || die 52 "make $ALLBINS failed"
		BINS=""; for i in $ALLBINS ;do BINS="$BINS bin/$i" ;done
		msg "cp -p $BINS $DIRNAME/"
		cp -p $BINS $DIRNAME || die 53 "can't cp $BINS"
	fi

	# exec
	DT=`date '+%m%d'`

	do_sdv14 $MAOPT
	do_sdnano $MAOPT
}


###
msg "# start"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
sudo ntpdate ntp.nict.jp

# check
if [ ! -d $TOPDIR ]; then
	if [ $CMD = "clone" ]; then
		msg "git clone $REMOTEURL"
		git clone $REMOTEURL || die 5 "can't clone $REMOTEURL, exit"
	else
		msg "${ESCRED}# can't find $TOPDIR, exit${ESCBACK}"
		exit 2
	fi
fi
if [ ! -d $BUILDPATH ]; then
	msg "mkdir -p $BUILDPATH"
	mkdir -p $BUILDPATH
	if [ ! -d $BUILDPATH ]; then
		msg "${ESCRED}# can't find $BUILDPATH, exit${ESCBACK}"
		exit 3
	fi
fi


msg "cd $BUILDPATH"
cd $BUILDPATH

msg "git branch"
git branch
msg "git checkout $BRANCH"
git checkout $BRANCH

msg "mkdir $DIRNAME"
mkdir $DIRNAME
if [ ! -e $DIRNAME ]; then
	msg "${ESCRED}no directory: $DIRNAME${ESCBACK}"
	exit 11
fi

case $CMD in
*sy*)	do_sync;;
*sync*)	do_sync;;
*)	msg "no sync";;
esac

case $CMD in
*cp*)	do_cp;;
*copy*)	do_cp;;
*)	msg "no copy";;
esac

case $CMD in
*cmk*)	do_cmk;;
*cmake*)	do_cmk;;
*)	msg "no cmake";;
esac

case $CMD in
*tst*)	do_test;;
*test*)	do_test;;
*)	msg "no make test";;
esac

case $CMD in
*noma*)		do_main NOEXEC;;
*nomain*)	do_main NOEXEC;;
*maonly*)	do_main NOMAKE;;
*mainonly*)	do_main NOMAKE;;
*ma*)		do_main;;
*main*)		do_main;;
*)		msg "no make main";;
esac

case $CMD in
*noex*)		do_examples NOEXEC;;
*exonly*)	do_examples NOMAKE;;
*ex*)		do_examples;;
*examples*)	do_examples;;
*)		msg "no make examples";;
esac

case $CMD in
*sd14only*)	do_sdv14 NOMAKE;;
*sd14*)		do_sdv14;;
esac

case $CMD in
*sdnanoonly*)	do_sdnano NOMAKE;;
*sdnano*)	do_sdnano;;
esac

msg "# done."

