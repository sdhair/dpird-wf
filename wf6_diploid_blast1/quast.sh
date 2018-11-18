#!/bin/bash -l

# project id
account=director2091

#SBATCH --job-name=quast.qc
#SBATCH --output=%x.out
#SBATCH --account=director2091
#SBATCH --clusters=zeus
#SBATCH --partition=workq
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --mem=10G
#SBATCH --export=NONE

# directory names
# some assumptions are in place:
# sample name = name of current directory
sample=$(basename $(pwd))
# storage directory = directory containing current directory (e.g. contains each sample as sub-directory)
basegroup=$(dirname $(pwd))
# scratch directory =
# 1. if storage in group, reflects its name under scratch
# 2. if storage in scratch, gets a "_tmp" suffix
basescratch=${basegroup/group/scratch}
if [ $basescratch == $basegroup ] ; then
 basescratch=${basegroup}_tmp
fi
# compose full directory names
group="$basegroup/$sample"
scratch="$basescratch/$sample"

# shifter definitions
module load shifter
srun_cmd="srun --export=all"
quast_cont="quay.io/biocontainers/quast:5.0.1--py27pl526ha92aebf_0"

# create scratch
mkdir -p $scratch

# copying input data to scratch
cp -p $group/*.fasta $scratch/

# running
cd $scratch
echo Group directory : $group
echo Scratch directory : $scratch
echo SLURM job id : $SLURM_JOB_ID

echo TIME quast start $(date)
$srun_cmd shifter run $quast_cont quast.py \
        *.fasta \
        --min-contig 100
echo TIME quast end $(date)

# create output directory
mkdir -p $group/$sample\_quast

# Copying output data back to group
cp -r -p $scratch/quast_results/result* $group/$sample\_quast
