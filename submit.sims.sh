#!/bin/bash

# Initialize variables
scriptDir=${0%/*}
pyScriptName=$scriptDir/perform.ti.py
charmm="charmm"
numproc=1
PARFILES=()
topfile=
TOPFILES=()
solute=
solvent=
lpun=
nsteps=20000
nequil=10000
remote=
SIMTYPES=("vdw" "pcsg" "mtp")
lambda_i=0.0
lambda_step=0.02
lambda_f=1.0

function show_help 
{
  echo -ne "Usage: \n$0 [-c charmm] [-n numProc] [-p file.par] <-t file.top>\n\
    [-q file.top] <-o solute.pdb> [-l solvent.pdb]\n\
    [-m file.lpun] [-a NSTEPS] [-e NEQUIL] [-r remote.cluster]\n\
    [-i lambda_i] [-d lambda_step] [-f lambda_f]\n"
}

function exists_or_die
{
  [ -z $1 ] && echo "Missing file $2" && exit 1
}

function contains() {
    local n=$#
    local value=${!n}
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "y"
            return 0
        fi
    }
    echo "n"
    return 1
}

OPTIND=1
while getopts "h?:c:n:p:t:q:o:l:m:g:e:r:i:d:f:" opt; do
  case "$opt" in
    h|\?)
      show_help
      exit 0
      ;;
    c)
      charmm=$OPTARG
      ;;
    n)
      numproc=$OPTARG
      [ $numproc -lt 1 ] && die "Error in number of CPUs"
      ;;
    p)
      PARFILES+=("--par $OPTARG")
      echo "option PARFILES: ${PARFILES[@]}"
      ;;
    t)
      topfile=$OPTARG
      echo "option topfile: $topfile"
      ;;
    q)
      TOPFILES+=("--top $OPTARG")
      echo "option TOPFILES: ${TOPFILES[@]}"
      ;;
    o)
      solute=$OPTARG
      echo "option solute: $solute"
      ;;
    l)
      solvent="--slv $OPTARG"
      echo "option solvent: $solvent"
      ;;
    m)
      lpun="--lpun $OPTARG"
      echo "option lpun: $lpun"
      ;;
    g)
      nsteps=$OPTARG
      echo "option nsteps: $nsteps"
      ;;
    e)
      nequil=$OPTARG
      echo "option nequil: $nequil"
      ;;
    r)
      remote="--rem $OPTARG"
      echo "option remote: $remote"
      ;;
    i)
      lambda_i=$OPTARG
      echo "option lambda_i: $lambda_i"
      ;;
    d)
      lambda_step=$OPTARG
      echo "option lambda_step: $lambda_step"
      ;;
    f)
      lambda_f=$OPTARG
      echo "option lambda_f: $lambda_f"
      ;;
  esac
done
shift $((OPTIND-1)) # Shift off the options

exists_or_die $topfile "topfile"
exists_or_die $solute "solute"
exists_or_die $lpun "lpun"


for simtype in ${SIMTYPES[@]}
do
  filename=ti.$simtype.$nsteps.$lambda_step.out
  echo "Running $simtype; saving output to $filename"
  # Submit jobs
  $pyScriptName \
    --chm $charmm \
    --tps $topfile \
    ${TOPFILES[@]} \
    ${PARFILES[@]} \
    --ti $simtype \
    --slu $solute \
    $solvent \
    $lpun \
    --nst $nsteps \
    --neq $nequil \
    $remote \
    --lmb $lambda_i $lambda_step $lambda_f \
    --num $numproc > $filename
done

