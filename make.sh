#!/bin/bash -l

#PBS -j oe
<<<<<<< HEAD
#PBS -l walltime=48:00:00
#PBS -l nodes=1:ppn=2
=======
#PBS -l walltime=480:00:00
#PBS -l nodes=1:ppn=16
>>>>>>> 26aaf9713aba69e1ddba8d4251f7677dc58a59d9
#PBS -l mem=256gb
##PBS -q highmem

cd $PBS_O_WORKDIR

<<<<<<< HEAD
export mpiCores="$PBS_NP"
# module load R/3.2.0
# make -e working/domainSelectivity.pdf 
src/computeStats.R working/pubchemBioassay.sqlite working/bioassayMirror working/summarystats.txt
=======
export cores="$PBS_NP"
# module load R/3.2.0
make -e all 
>>>>>>> 26aaf9713aba69e1ddba8d4251f7677dc58a59d9
