#!/bin/bash -l

#PBS -j oe
#PBS -l walltime=480:00:00
#PBS -l nodes=1:ppn=16
#PBS -l mem=256gb
##PBS -q highmem

cd $PBS_O_WORKDIR

export cores="$PBS_NP"
# module load R/3.2.0
make -e all 
