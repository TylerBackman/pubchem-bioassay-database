#!/bin/bash

#PBS -j oe
#PBS -l nodes=1:ppn=1
##PBS -l nodes=n08:ppn=4+n09:ppn=4
#PBS -l mem=2gb 
#PBS -l walltime=880:00:00 
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
