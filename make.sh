#!/bin/bash -l

#PBS -j oe
#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=8
#PBS -l mem=64gb
##PBS -q highmem

cd $PBS_O_WORKDIR

export mpiCores="$PBS_NP"
module load R/3.2.2 
make -e working/summarystats.txt
