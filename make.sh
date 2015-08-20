#!/bin/bash -l

#PBS -j oe
#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=2
#PBS -l mem=256gb
##PBS -q highmem

cd $PBS_O_WORKDIR

export mpiCores="$PBS_NP"
# module load R/3.2.0
# make -e working/domainSelectivity.pdf 
src/computeStats.R working/pubchemBioassay.sqlite working/bioassayMirror working/summarystats.txt
