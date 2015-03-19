#!/bin/bash

#PBS -j oe
#PBS -l nodes=1:ppn=1
#PBS -l mem=16gb 
#PBS -l walltime=48:00:00 
#PBS -q highmem 

cd $PBS_O_WORKDIR

# Load Module System
source /usr/local/Modules/3.2.9/init/bash

# Load needed modules
module load torque
module load openmpi
module load openbabel

export mpiCores="$PBS_NP"
make -e working/pubchemBioassay.sqlite
# make -e working/kClust 
