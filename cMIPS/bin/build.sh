#!/bin/bash

## ------------------------------------------------------------------------
## cMIPS, Roberto Hexsel, 30set2013, rev 08jan2015, 04apr2017
## ------------------------------------------------------------------------

# set -x

errorED()
{
cat <<EOF


        $pkg_vhd NEWER than header files;
        problem running edMemory.sh in $0


EOF
exit 1
}


errorCOMPILING()
{
cat <<EOF


        $0: error in compiling VHDL sources
            remove cMIPS/vhdl/.last_import and cMIPS/vhdl/work-obj93.cf
            and re-compile

EOF
exit 1
}


usage()
{
cat << EOF
usage:  $0 [options]
        creates VHDL simulator

OPTIONS:
   -h    Show this message
   -syn  Compile for Macnica's board, else for simulation
   -new  Automagically update all addresses (packageMemory.vhd changed)
   -x    turn on "set -x"
EOF
}


synth=false
pacMem_changed=false

while true ; do
    case "$1" in
        -h) usage ; exit 1
            ;;
        -syn | -mif ) synth=true
            ;;
        -new ) pacMem_changed=true
            ;;
        -x) set -x
            ;;
        *)  break ; #usage
	    # echo "  invalid option: $1"; exit 1
            ;;
    esac
    shift
done



if [ ! -v tree ] ; then
  # you must set the location of the cMIPS root directory in the variable tree
  # tree=${HOME}/cMIPS
  # tree=${HOME}/cmips/cMIPS
  export tree="$(echo $PWD | sed -e 's:^\(/.*/cMIPS\)/.*:\1:')"
fi


bin="${tree}"/bin
include="${tree}"/include
srcVHDL="${tree}"/vhdl


c_ld="${include}"/cMIPS.ld
c_s="${include}"/cMIPS.s
c_h="${include}"/cMIPS.h


if [ $synth = true ] ; then
    pkg_vhd="$srcVHDL/packageMemory_fpga.vhd"
    (cd $srcVHDL ; ln -s -f packageMemory_fpga.vhd packageMemory.vhd)
else
    pkg_vhd="$srcVHDL/packageMemory_simu.vhd"
    (cd $srcVHDL ; ln -s -f packageMemory_simu.vhd packageMemory.vhd)
fi

if [ $pkg_vhd -nt $c_ld -o\
     $pkg_vhd -nt $c_s  -o\
     $pkg_vhd -nt $c_h  -o\
     ! -f ${srcVHDL}/.last_import ] ; then
   "${bin}"/edMemory.sh -v || errorED || exit 1
fi

if [ $pacMem_changed ] ; then
   "${bin}"/edMemory.sh -v || errorED || exit 1
fi

cd "${srcVHDL}"

simulator=tb_cmips

pkg="packageWires.vhd packageMemory.vhd packageExcp.vhd"

src="aux.vhd altera.vhd macnica.vhd cache.vhd instrcache.vhd sdram.vhd ram.vhd rom.vhd units.vhd SDcard.vhd io.vhd uart.vhd fpu.vhd disk.vhd pipestages.vhd exception.vhd core.vhd tb_cMIPS.vhd"

# build simulator
#ghdl --clean
#ghdl -a --ieee=standard "${srcVHDL}"/packageWires.vhd   || exit 1
#ghdl -a --ieee=standard "${srcVHDL}"/packageMemory.vhd  || exit 1
#ghdl -a --ieee=standard "${srcVHDL}"/packageExcp.vhd    || exit 1
#for F in ${src} ; do
#    if [ ! -s ${F%.vhd}.o  -o  "${srcVHDL}"/${F} -nt ${F%.vhd}.o ] ; then
#	ghdl -a --ieee=standard "${srcVHDL}"/${F}        || exit 1
#    fi
#done
#
#ghdl -c "${srcVHDL}"/*.vhd -e ${simulator}              || exit 1


# NOTE: when you add a new sourcefile to this project, you must include it
#       with "ghdl -i newFile.vhd" so that ghdl learns about it.  It may be
#       a good idea to remove ./.last_import to force a full rebuild.
#       Of course, newFile.vhd must be added to the $src variable (above).

# if never imported sources, do it now
if [ ! -f .last_import ] ; then
   ghdl -i ${pkg}
   ghdl -i ${src}
   touch .last_import
fi

ghdl -m --std=02 ${simulator} || errorCOMPILING

mv ${simulator} ..

cd ..

