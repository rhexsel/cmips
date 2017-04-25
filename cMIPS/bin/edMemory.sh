#!/bin/bash

# edit header files in case of change in variable definitions 

# set -x

# bail out on any error
set -e

usage() {
cat << EOF
usage:  $0 [options]
        edits cMIPS.ld cMIPS.h cMIPS.s to keep addresses up to date

OPTIONS:
   -h    Show this message
   -v    Verbose, shows new values
EOF
}

verbose=false

while [ -n "$1" ] ; do
    case "$1" in
        -h) usage ; exit 1
            ;;
        -v) verbose=true
            ;;
        *)  usage ; echo "   invalid option: $1" ; exit 1
            ;;
    esac
    shift
done



if [ ! -v tree ] ; then
  # you must set the location of the cMIPS root directory in the variable tree
  # tree=${HOME}/cMIPS
  # tree="$(dirname "$(pwd)")"
  export tree="$(echo $PWD | sed -e 's:\(/.*/cMIPS\)/.*:\1:')"
fi

bin="${tree}"/bin
include="${tree}"/include
srcVHDL="${tree}"/vhdl


dfn="${srcVHDL}"/packageMemory.vhd

# shell version for linker
lnk="${include}"/cMIPS.ld
# C version
hdr="${include}"/cMIPS.h
# assembly version
asm="${include}"/cMIPS.s


VARIABLES="x_INST_BASE_ADDR x_INST_MEM_SZ x_DATA_BASE_ADDR x_DATA_MEM_SZ x_IO_BASE_ADDR x_IO_MEM_SZ x_IO_ADDR_RANGE x_SDRAM_BASE_ADDR x_SDRAM_MEM_SZ"

EXCEPTION_VECTORS="x_EXCEPTION_0000 x_EXCEPTION_0100 x_EXCEPTION_0180 x_EXCEPTION_0200 x_EXCEPTION_BFC0 x_ENTRY_POINT"

if [ "${dfn}" -nt "${lnk}" ] ||\
   [ "${dfn}" -nt "${asm}" ] ||\
   [ "${dfn}" -nt "${hdr}" ] ||\
   [ ! -f ${srcVHDL}/.last_include  ] ;
then

  cp "${asm}" "${asm}"~
  for VAR in $VARIABLES $EXCEPTION_VECTORS ; do
    NEW=$(egrep -h ${VAR} "${dfn}"|sed -n -e '/reg32/s/.*x"\(.*\)".*/\1/p')
    OLD=$(egrep -h ${VAR} "${asm}"|sed -n -e 's/.*, *0x\(.*\)[^0-9a-fA-F]*/\1/p')
    # echo -n -e "$NEW $OLD\n"
    if [ -n "$OLD" ] ; then
	sed -i -e '/'$VAR'/s/'$OLD'/'$NEW'/' "${asm}"
    fi
  done

  cp "${lnk}" "${lnk}"~
  for VAR in $VARIABLES ; do
    NEW=$(egrep -h ${VAR} "${dfn}" | sed -n -e '/reg32/s/.*x"\(.*\)".*/\1/p')
    OLD=$(egrep -h ${VAR} "${lnk}" | sed -n -e 's/.* = 0x\(.*\), .*/\1/p')
    # echo -n -e "$NEW $OLD\n"
    if [ -n "$OLD" ] ; then
	sed -i -e '/'$VAR'/s/'$OLD'/'$NEW'/' "${lnk}"
    fi
  done

  # set up address for base of Page Table
  VAR=x_DATA_BASE_ADDR
  NEW=$(egrep -h ${VAR} "${dfn}" | sed -n -e '/reg32/s/.*x"\(.*\)".*/\1/p')
  OLD=$(egrep -h ${VAR} "${lnk}" | sed -n -e 's/.* = 0x\(.*\); .*/\1/p')
  # echo -n -e "$NEW $OLD\n"
  if [ -n "$OLD" ] ; then
     sed -i -e '/'$VAR'/s/'$OLD'/'$NEW'/' "${lnk}"
  fi

  # set up address for base of Page Table
  VAR=x_DATA_MEM_SZ
  NEW=$(egrep -h ${VAR} "${dfn}" | sed -n -e '/reg32/s/.*x"\(.*\)".*/\1/p')
  OLD=$(egrep -h ${VAR} "${lnk}" | sed -n -e 's/.* = 0x\(.*\); .*/\1/p')
  # echo -n -e "$NEW $OLD\n"
  if [ -n "$OLD" ] ; then
     sed -i -e '/'$VAR'/s/'$OLD'/'$NEW'/' "${lnk}"
  fi

  cp "${hdr}" "${hdr}"~
  for VAR in $VARIABLES ; do
    NEW=$(egrep -h ${VAR} "${dfn}"|sed -n -e '/reg32/s/.*x"\(.*\)".*/\1/p')
    OLD=$(egrep -h ${VAR} "${hdr}"|sed -n -e 's/.* 0x\(.*\)[^0-9a-fA-F]*/\1/p')
    # echo -n -e "$NEW $OLD\n"
    if [ -n "$OLD" ] ; then
	sed -i -e '/'$VAR'/s/'$OLD'/'$NEW'/' "${hdr}"
    fi
  done

fi

set +e
if [ $verbose = true ] ; then
    diff ${hdr}{,~}
    diff ${lnk}{,~}
    diff ${asm}{,~}
fi

exit 0
