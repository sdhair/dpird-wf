#!/bin/bash -l

#SBATCH --job-name=trim.qc
#SBATCH --output=%x.out
#SBATCH --account=director2091
#SBATCH --clusters=zeus
#SBATCH --partition=workq
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem=10G
#SBATCH --export=NONE 


# sample id and working directories
sample=
group=
scratch=

# shifter definitions
module load shifter
srun_cmd="srun --export=all"
bbmap_cont="quay.io/biocontainers/bbmap:38.20--h470a237_0"
fastqc_cont="quay.io/biocontainers/fastqc:0.11.7--4"


# copying input data to scratch
for f in interleaved.fastq.gz ; do
 if [ ! -f $scratch/$f ] ; then
  cp -p $group/$f $scratch/
 fi
done

# running
cd $scratch
echo Group directory : $group
echo Scratch directory : $scratch
echo SLURM job id : $SLURM_JOB_ID

echo TIME trim1 start $(date)
$srun_cmd shifter run $bbmap_cont bbduk.sh \
	in=interleaved.fastq.gz \
	out=trimmed-partial.fastq.gz \
	interleaved=t \
	ref=adapters ktrim=r k=27 hdist=2 edist=0 mink=4
echo TIME trim1 end $(date)

$srun_cmd shifter run $bbmap_cont bbduk.sh \
	in=trimmed-partial.fastq.gz \
	out=clean.fastq.gz \
	interleaved=t \
	ref=adapters ktrim=l k=27 hdist=2 edist=0 mink=4 \
	qtrim=rl trimq=13 \
	minlength=30
echo TIME trim2 end $(date)

$srun_cmd shifter run $fastqc_cont fastqc clean.fastq.gz
echo TIME qc end $(date)

# copying output data back to group
cp -p $scratch/clean* $group/
