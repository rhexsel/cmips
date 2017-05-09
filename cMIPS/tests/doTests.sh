#!/bin/bash

# set -x

if [ ! -v tree ] ; then
  # you must set the location of the cMIPS root directory in the variable tree
  # tree=${HOME}/cmips-code/cMIPS
  # tree=${HOME}/cMIPS
  export tree="$(echo $PWD | sed -e 's:^\(/.*/cMIPS\)/.*:\1:')"
fi


# path to cross-compiler and binutils must be set to your installation
WORK_PATH=/home/soft/linux/mips/cross/bin
HOME_PATH=/opt/cross/bin

if [ -x /opt/cross/bin/mips-gcc ] ; then
    export PATH=$PATH:$HOME_PATH
elif [ -x /home/soft/linux/mips/cross/bin/mips-gcc ] ; then
    export PATH=$PATH:$WORK_PATH
else
    echo "\n\n\tPANIC: cross-compiler not installed\n\n" ; exit 1;
fi


bin=${tree}/bin
include=${tree}/include
srcVHDL=${tree}/vhdl

simulator=$tree/tb_cmips

usage() {
cat << EOF
usage:  $0 [options] 
        re-create simulator/model and simulate several test programs

OPTIONS:
   -h    Show this message
   -B    ignore blank space in comparing simulation to expected results
   -f    do a full test (takes longer)
EOF
}

# -c    simulate only programs that are timing independent: can use caches

ignBLANKS=""
withCache=false
fullTest=false

while true ; do

    case "$1" in
        -h | "-?") usage ; exit 1
            ;;
        -B) ignBLANKS="-B"
            ;;
        #-c) withCache=true
        #    ;;
        -f | -F) fullTest=true
            ;;
        -x) set -x
            ;;
        "") break
            ;;
        *) usage ; echo "  invalid option: $1"; exit 1
            ;;
    esac
    shift
done

touch input.data serial.inp

a_FWD="fwdAddAddAddSw fwd_SW lwFWDsw lwFWDsw2 slt32 slt_u_32 slt_s_32 reg0"
a_CAC="dCacheTst lhUshUCache lbUsbUCache lbsbCache dCacheTstH dCacheTstB"
a_BEQ="lw-bne bXtz sltbeq beq_dlySlot jr_dlySlot interr_x2 interrJR_dlySlot"
a_FUN="jaljr jr_2 jal_fun_jr jalr_jr jallwjr bltzal_fun_jr"
a_OTH="mult div nullifies mul sll slr movz wsbh_seb extract insert"
a_BHW="lbsb lhsh lwsw lwswIncr swlw lwl_lwr"
a_MEM="lwSweepRAM"
a_CTR="teq_tne teq_jal teq_lw tlt_tlti tltu_tgeu eiDI ll_sc overflow counter"
a_COP="mtc0CAUSE2 mtc0EPC syscall break mfc0CONFIG badVAddr badVAddrMM"
a_MMU="mmu_index mmu_tlbwi mmu_tlbp mmu_tlbwr mmu_context"
a_EX1="mmu_refill mmu_refill2 mmu_refill3 mmu_inval mmu_inval2"
a_EX2="mmu_mod mmu_mod2 mmu_double mmu_double2 busError_d busError_i"

if [ $fullTest = true ] ; then
   a_tests=$(echo $a_FWD $a_CAC $a_BEQ $a_FUN $a_OTH $a_BHW $a_MEM $a_CTR $a_COP $a_MMU $a_EX1 $a_EX2)
else
   a_tests=$(echo $a_BEQ $a_FUN $a_BHW $a_CTR $a_COP $a_EX2)
fi

## force an update of all include files with edMemory.sh
touch -t 201501010000.00 ../include/cMIPS.*

(cd $tree ; $bin/build.sh) || exit 1

rm -f *.simout *.elf

stoptime=500us

for F in $(echo $a_tests); do
	$bin/assemble.sh ${F}.s || exit 1
	${simulator} --ieee-asserts=disable --stop-time=$stoptime \
            2>/dev/null   >$F.simout
	diff $ignBLANKS -q $F.expected $F.simout
	if [ $? == 0 ] ; then
	    echo -e "\t $F"
	    rm -f ${F}.{elf,o,simout,map}
	else
	    echo -e "\n\n\tERROR in $F\n\n"
	    diff -a $F.expected $F.simout
	    exit 1
	fi
done


c_small="divmul fat fib count sieve ccitt16 gcd matrix negcnt reduz rand"
c_types="pointer xram sort-byte sort-half sort-int memcpy"
c_sorts="bubble insertion merge quick selection shell"
c_FPU="FPU_m"

## the tests below MUST be run with FAKE CACHES
c_timing="extCounter extCounterInt"
c_uart="uarttx uartrx uart_irx"

## the tests below MUST be run with TRUE CACHES
c_stats="sumSstats"

## the simulation time is far too long # c_2slow="dct-int"

if [ $fullTest = true ] ; then
   c_tests=$(echo $c_small $c_types $c_sorts $c_FPU $c_timing $c_uart)
else
   c_tests=$(echo $c_small $c_types $c_timing $c_uart)
fi

echo -e "\nabcdef\n012345\n" >serial.inp

stoptime=1ms

if [ $withCache = true ] ; then
  SIMULATE="$c_small $c_types $c_sorts"
else
  SIMULATE="$c_small $c_types $c_sorts $c_FPU $c_timing $c_uart"
  # make sure all memory latencies are ZERO
  # pack=$srcVHDL/packageWires.vhd
  # sed -i -e "/ROM_WAIT_STATES/s/ := \([0-9][0-9]*\);/ := 0;/" \
  #        -e "/RAM_WAIT_STATES/s/ := \([0-9][0-9]*\);/ := 0;/" \
  #        -e "/IO_WAIT_STATES/s/ := \([0-9][0-9]*\);/ := 0;/" $pack
fi

## for F in $(echo "$SIMULATE" ) ; do 
for F in $(echo $c_tests) ; do 
    $bin/compile.sh -O3 ${F}.c  || exit 1
    ${simulator} --ieee-asserts=disable --stop-time=$stoptime \
          2>/dev/null >$F.simout
    diff $ignBLANKS -q $F.expected $F.simout
    if [ $? == 0 ] ; then
	echo -e "\t $F"
	rm -f ${F}.{elf,s,o,simout,map}
    else
	echo -e "\n\n\tERROR in $F\n\n"
	diff -a $F.expected $F.simout
	exit 1
    fi
done

