#!/bin/bash

#PBS -j oe
#PBS -l nodes=2:ppn=2
##PBS -l nodes=n08:ppn=1+n09:ppn=1
##PBS -l mem=4gb 
#PBS -l mem=1gb 
##PBS -l walltime=440:00:00 
#PBS -l walltime=1:00:00 
##PBS -q highmem 

cd $PBS_O_WORKDIR

# Load Module System
source /usr/local/Modules/3.2.9/init/bash

# Load needed modules
module load torque
module load openmpi
module load openbabel

export mpiCores="$PBS_NP"
make -e working/eiDatabase
