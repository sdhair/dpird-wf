#!/bin/bash -l

#SBATCH --job-name=map_contigs
#SBATCH --output=%x.out
#SBATCH --account=director2091
#SBATCH --clusters=zeus
#SBATCH --partition=workq
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --time=24:00:00
#SBATCH --mem=10G
#SBATCH --export=NONE 
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# sample id and working directories
sample=
group=
scratch=

# shifter definitions
module load shifter
srun_cmd="srun --export=all"
bbmap_cont="quay.io/biocontainers/bbmap:38.20--h470a237_0"
samtools_cont="dpirdmk/samtools:1.9"
bcftools_cont="dpirdmk/bcftools:1.9"


# copying input data to scratch
for f in clean.fastq.gz contigs_sub.fasta ; do
 if [ ! -f $scratch/$f ] ; then
  cp -p $group/$f $scratch/
 fi
done

# running
cd $scratch
echo Group directory : $group
echo Scratch directory : $scratch
echo SLURM job id : $SLURM_JOB_ID

# alignment (sorted BAM file as final output)
echo TIME map_contigs bbmap start $(date)
$srun_cmd shifter run $bbmap_cont bbmap.sh \
	in=clean.fastq.gz ref=contigs_sub.fasta \
	out=mapped_contigs_sub_unsorted.sam \
	interleaved=t \
	k=13 maxindel=16000 ambig=random \
	threads=$OMP_NUM_THREADS
echo TIME map_contigs bbmap end $(date)

$srun_cmd shifter run $samtools_cont samtools \
    view -b -o mapped_contigs_sub_unsorted.bam mapped_contigs_sub_unsorted.sam
echo TIME map_contigs sam view end $(date)

$srun_cmd shifter run $samtools_cont samtools \
    sort -o mapped_contigs_sub.bam mapped_contigs_sub_unsorted.bam
echo TIME map_contigs sam sort end $(date)

$srun_cmd shifter run $samtools_cont samtools \
    index mapped_contigs_sub.bam
echo TIME map_contigs sam index end $(date)

# depth data into text file
$srun_cmd shifter run $samtools_cont samtools \
	depth -aa mapped_contigs_sub.bam >depth_contigs_sub.dat
echo TIME map_contigs sam depth end $(date)

# creating consensus sequence
$srun_cmd shifter run $bcftools_cont bcftools \
	mpileup -Ou -f contigs_sub.fasta mapped_contigs_sub.bam \
	| shifter run $bcftools_cont bcftools \
	call --ploidy 1 -mv -Oz -o calls_contigs_sub.vcf.gz
echo TIME map_contigs bcf mpileup/call end $(date)

$srun_cmd shifter run $bcftools_cont bcftools \
	tabix calls_contigs_sub.vcf.gz
echo TIME map_contigs bcf tabix end $(date)

$srun_cmd shifter run $bcftools_cont bcftools \
	consensus -f contigs_sub.fasta -o consensus_contigs_sub.fasta calls_contigs_sub.vcf.gz
echo TIME map_contigs bcf consensus end $(date)

# copying output data back to group
cp -p $scratch/mapped_contigs_sub.bam* $scratch/depth_contigs_sub.dat $scratch/consensus_contigs_sub.fasta $group/
