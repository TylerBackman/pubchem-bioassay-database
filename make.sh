#!/bin/bash

#PBS -j oe
##PBS -l nodes=4:ppn=8
##PBS -l nodes=n08:ppn=8+n09:ppn=8
#PBS -l nodes=n08:ppn=8
#PBS -l mem=15gb 
#PBS -l walltime=880:00:00 
##PBS -q highmem 

cd $PBS_O_WORKDIR

# Load Module System
source /usr/local/Modules/3.2.9/init/bash

# Load needed modules
module load torque
module load openmpi
module load openbabel

# use old R to get eiR 1.2.0
# module load R/3.0.2

export mpiCores="$PBS_NP"
# make -e working/eiDatabase
# make -e working/indexedEiDatabase 
make -e working/bioassayDatabaseNoDuplicates.sqlite
