#!/bin/bash -l

#SBATCH --job-name=assemble
#SBATCH --output=%x.out
#SBATCH --account=director2091
#SBATCH --clusters=zeus
#SBATCH --partition=workq
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00
#SBATCH --mem=60G
#SBATCH --export=NONE 
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# sample id and working directories
sample=""
group=""
scratch=""

# shifter definitions
module load shifter
srun_cmd="srun --export=all"
spades_cont="quay.io/biocontainers/spades:3.12.0--1"


# copying input data to scratch
for f in clean.fastq.gz ; do
 if [ ! -f $scratch/$f ] ; then
  cp -p $group/$f $scratch/
 fi
done

# running
cd $scratch
echo Group directory : $group
echo Scratch directory : $scratch
echo SLURM job id : $SLURM_JOB_ID

echo TIME assemble start $(date)
$srun_cmd shifter run $spades_cont dipspades.py \
	--12 clean.fastq.gz \
	--careful \
	-t $OMP_NUM_THREADS -m $((SLURM_MEM_PER_NODE/1024)) \
	-o .
echo TIME assemble end $(date)

min_len_contig=100
awk -v min_len_contig=$min_len_contig -F _ '{ if( $1 == ">NODE" ){ if( $4 < min_len_contig ) {exit} } ; print }' contigs.fasta >contigs_sub.fasta
echo TIME subset end $(date)

# copying output data back to group
cp -p $scratch/contigs.fasta $group/contigs_ALL.fasta
cp -p $scratch/contigs_sub.fasta $group/
