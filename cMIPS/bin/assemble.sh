#!/bin/bash

# set -x

if [ ! -v tree ] ; then
  # you must set the location of the cMIPS root directory in the variable tree
  # tree=${HOME}/cMIPS
  # export tree="$(dirname "$(pwd)")"
  export tree="$(echo $PWD | sed -e 's:\(/.*/cMIPS\)/.*:\1:')"
fi


# path to cross-compiler and binutils must be set to your installation
WORK_PATH=/home/soft/linux/mips/cross/bin
HOME_PATH=/opt/cross/bin

if [ -x /opt/cross/bin/mips-gcc ] ; then
    export PATH=$PATH:$HOME_PATH
elif [ -x /home/soft/linux/mips/cross/bin/mips-gcc ] ; then
    export PATH=$PATH:$WORK_PATH
else
    echo -e "\n\n\tPANIC: cross-compiler not installed\n\n" ; exit 1;
fi


usage() {
cat << EOF
usage:  $0 [options] SOURCE.s
        creates {prog,data}.bin to be input by textbench

OPTIONS:
   -h    Show this message
   -O n  Optimization level, defaults to n=0 {0,1,2,3}
   -v    Verbose, creates memory map: SOURCE.map
   -n    when verbose, display register names instead of numbers
   -mif  Generate output file ROM.mif for Altera's FPGAs
EOF
}

errorED()
{
cat <<EOF


	$pkg_vhd NEWER than header files;
	problem running edMemory.sh in $0


EOF
exit 1
}


if [ $# = 0 ] ; then usage ; exit 1 ; fi

miffile=false
pacMem_changed=false
verbose=false
names=false
unset mem_map
level=0


bin="${tree}"/bin
include="${tree}"/include
srcVHDL="${tree}"/vhdl


c_ld="${include}"/cMIPS.ld
c_s="${include}"/cMIPS.s

while true ; do

    case "$1" in
        -h) usage ; exit 1
            ;;
        -O) level=$2
            shift
            ;;
	-O1) level=1
	    ;;
	-O2) level=2
	    ;;
	-O3) level=3
	    ;;
        -v) verbose=true
            ;;
        -n) names=true
            ;;
        -mif | -syn ) miffile=true
            ;;
        -new ) pacMem_changed=true
	    ;;
        -x) set -x
            ;;
        *)  inp=${1%.s}
            if [ ${inp}.s != $1 ] ; then
                usage ; echo "  invalid option: $1"; exit 1 ; fi
            break
            ;;
    esac
    shift
done

if [ -z $inp ] ; then usage ; exit 1 ; fi

# pkg_vhd="${srcVHDL}"/packageMemory.vhd

if [ $miffile = true ]; then
   S="-D FOR_SYNTHESIS" ;
   pkg_vhd="${srcVHDL}"/packageMemory_fpga.vhd
   (cd $srcVHDL ; ln -s -f packageMemory_fpga.vhd packageMemory.vhd)
   # ln -sf ${srcVHDL}/packageMemory_fpga.vhd $pkg_vhd 
   # touch $pkg_vhd 
else 
   S="-U FOR_SYNTHESIS" ;
   pkg_vhd="${srcVHDL}"/packageMemory_simu.vhd
   (cd $srcVHDL ; ln -s -f packageMemory_simu.vhd packageMemory.vhd)
   # ln -sf ${srcVHDL}/packageMemory_simu.vhd $pkg_vhd
   # touch $pkg_vhd 
fi


if [ $pacMem_changed -o\
     $pkg_vhd -nt $c_ld -o\
     $pkg_vhd -nt $c_s ] ; then
    "${bin}"/edMemory.sh -v || errorED || exit 1
fi

if [ $verbose = true ] ; then  mem_map="-Map ${inp}.map" ; fi

if [ $names = true ] ; then
   reg_names="-M reg-names=mips2r2 -M cp0-names=mips2r2" 
else
   reg_names="-M reg-names=numeric -M cp0-names=numeric"
fi 

asm=${inp}.s
obj=${inp}.o
elf=${inp}.elf
bin=prog.bin
dat=data.bin

(mips-as -O${level} -EL -mips32r2  -I "${include}" -o $obj $asm || exit 1) &&\
  mips-ld -EL ${mem_map} -I "${include}" --script $c_ld -o $elf $obj &&\
  mips-objcopy -S -j .text -O binary $elf $bin &&\
  mips-objcopy -S -j .data -j .rodata -j .PT -O binary $elf $dat &&\
  chmod a-x $bin $dat &&\
  if [ $verbose = true ] ; then
    mips-objdump -z -D -EL  $reg_names  --show-raw-insn \
        --section .text --section .data --section .rodata --section .bss  $elf
  fi &&\
  if [ $miffile = true ] ; then
    elf2mif.sh "$elf" || exit 1
  fi

#        --section .reginfo

