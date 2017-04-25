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
usage:  $0 some_file_name.elf
        creates ROM.mif from an ELF object file some_file_name.elf

OPTIONS:
   -h    Show this message
EOF
}


if [ $# = 0 ] ; then usage ; exit 1 ; fi

inp=${1%.elf}

if [ ${inp}.elf != $1 ] ; then
   usage ; echo "  invalid input: $1"; exit 1
fi
   
elf=$1


x_ROM_BASE=$(sed -n '/x_INST_BASE_ADDR/s/.*:= x"\(.*\)".*$/\1/p' $tree/vhdl/packageMemory.vhd)

ROM_BASE=$((16#$x_ROM_BASE))

x_ROM_SIZE=$(sed -n '/x_INST_MEM_SZ/s/.*:= x"\(.*\)".*$/\1/p' $tree/vhdl/packageMemory.vhd)

ROM_SZ=$((16#$x_ROM_SIZE))

mif=ROM.mif
tmp=ROM.tmp

mips-objdump -z -D -EL --section .text $elf |\
    sed -e '1,6d' -e '/^$/d' -e '/^ /!d' -e 's:\t: :g' \
        -e 's#^ *\([a-f0-9]*\): *\(........\)  *\(.*\)$#\2;#' |\
    awk 'BEGIN{c='$ROM_BASE';} //{ printf "%d : %s\n",c,$1 ; c=c+1; }' > $tmp

echo -e "\n-- cMIPS code\n\nDEPTH=${ROM_SZ};\nWIDTH=32;\n" > $mif
echo -e "ADDRESS_RADIX=DEC;\nDATA_RADIX=HEX;\nCONTENT BEGIN" >> $mif 
cat $tmp >> $mif
echo "END;" >> $mif




x_RAM_BASE=$(sed -n '/x_DATA_BASE_ADDR/s/.*:= x"\(.*\)".*$/\1/p' $tree/vhdl/packageMemory.vhd)

RAM_BASE=$((16#$x_RAM_BASE))

x_RAM_SIZE=$(sed -n '/x_DATA_MEM_SZ/s/.*:= x"\(.*\)".*$/\1/p' $tree/vhdl/packageMemory.vhd)

RAM_SZ=$((16#$x_RAM_SIZE))



mif=RAM.mif
tmp=RAM.tmp

mips-objdump -z -D -EL --section .data --section .rodata --section rodata1 --section .data1 --section .sdata --section .lit8 --section .lit4 --section .sbss --section .bss   $elf |\
    sed -e '1,6d' -e '/^$/d' -e '/^ /!d' -e 's:\t: :g' \
        -e 's#^ *\([a-f0-9]*\): *\(........\)  *\(.*\)$#\2;#' |\
    awk 'BEGIN{c='$RAM_BASE';} //{ printf "%d : %s\n",c,$1 ; c=c+1; }' > $tmp

echo -e "\n-- cMIPS data\n\nDEPTH=${RAM_SZ};\nWIDTH=32;\n" > $mif
echo -e "ADDRESS_RADIX=DEC;\nDATA_RADIX=HEX;\nCONTENT BEGIN" >> $mif 
cat $tmp >> $mif
echo "END;" >> $mif


# 
rm -f {ROM,RAM}.tmp


exit 0
