#!/bin/bash -l

#PBS -j oe
#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=2
#PBS -l mem=256gb
##PBS -q highmem

cd $PBS_O_WORKDIR

export mpiCores="$PBS_NP"
make -e working/summarystats.txt
