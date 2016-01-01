#!/bin/bash -l

#PBS -j oe
#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=1
#PBS -l mem=64gb
##PBS -q highmem

cd $PBS_O_WORKDIR

export cores="$PBS_NP"
module load hmmer/3.1b2
hmmpress working/Pfam-A.hmm
