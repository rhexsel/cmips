#!/bin/bash

## ------------------------------------------------------------------------
## classicalMIPS, Roberto Hexsel, 23nov2012-13nov2015
## ------------------------------------------------------------------------

# set -x


if [ ! -v tree ] ; then
  # you must set the location of the cMIPS root directory in the variable tree
  # tree=${HOME}/cMIPS
  # tree=${HOME}/cmips/cMIPS
  export tree="$(echo $PWD | sed -e 's:\(/.*/cMIPS\)/.*:\1:')"
fi

bin=${tree}/bin
include=${tree}/include
srcVHDL=${tree}/vhdl

simulator="${tree}"/tb_cmips

visual="${tree}"/cMIPS.vcd
unset WAVE

length=1
unit=m
gtkwconf=pipe
synth=

touch input.data input.txt serial.inp

usage() {
cat << EOF
usage:  $0 [options] 
        re-create simulator/model and run simulation
        prog.bin and data.bin must be in the current directory

OPTIONS:
   -h    Show this message
   -t T  number of time-units to run (default ${length})
   -u U  unit of time scale {m,u,n,p} (default ${unit}s)
   -n    send simulator output do /dev/null, else to v_cMIPS.vcd
   -w    invoke GTKWAVE -- stdin will not read input from keyboard
   -v F  gtkwave configuration file (e.g. pipe.sav, default v.sav)
   -syn  run simulation with synthesis RAM/ROM addresses
EOF
}

while true ; do

    case "$1" in
        -h | "-?") usage ; exit 1
            ;;
        -t) length=$2
            shift
            ;;
        -u) unit=$2
            shift
            ;;
	-n) visual=/dev/null
	    ;;
	-w) WAVE=true
	    ;;
	-syn | -mif ) synth="-syn"
	    ;;
        -v) gtkwconf=$2
            shift
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

gfile=${gtkwconf%%.sav}

sav="${tree}"/${gfile}.sav


"${bin}"/build.sh $synth || exit 1

options="--ieee-asserts=disable --stop-time=${length}${unit}s --vcd=${visual}"

if [ -v $WAVE ] ; then

  ## simulator must be exec'd so it can read from the standard input
  exec "${simulator}" $options --vcd-nodate

else 

  "${simulator}" $options ; gtkwave -O /dev/null -f ${visual} -a ${sav} &

fi



##  --wave=${visual%.vcd}.ghw

