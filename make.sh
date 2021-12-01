#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=10G
#SBATCH --time=1-00:15:00     # 1 day and 15 minutes
#SBATCH --mail-user=danicassol@gmail.com
#SBATCH --mail-type=ALL
#SBATCH --job-name="database"
#SBATCH -p girkelab # This is the default partition, you can use any of the following; intel, batch, highmem, gpu

cd $PBS_O_WORKDIR

export cores="$PBS_NP"
module load R/4.1.0_gcc-8.3.0
module load hmmer/3.3.2
make -e working/summarystats.txt
