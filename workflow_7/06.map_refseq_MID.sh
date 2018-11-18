#!/bin/bash -l

#SBATCH --job-name=map_refseq_MIDNUM
#SBATCH --output=%x.out
#SBATCH --account=director2091
#SBATCH --clusters=zeus
#SBATCH --partition=workq
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=06:00:00
#SBATCH --mem=10G
#SBATCH --export=NONE 
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

MID="MIDNUM"

# sample id and working directories
sample=
group=
scratch=

# shifter definitions
module load shifter
srun_cmd="srun --export=all"
blast_cont="quay.io/biocontainers/blast:2.7.1--h96bfa4b_5"
bbmap_cont="quay.io/biocontainers/bbmap:38.20--h470a237_0"
samtools_cont="dpirdmk/samtools:1.9"
bcftools_cont="dpirdmk/bcftools:1.9"


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

seqid=
echo map_refseq run number : ${MID}
echo map_refseq refseq ID : ${seqid}

# get ref sequence from BLAST db
echo TIME map_refseq blastdb start $(date)
$srun_cmd shifter run $blast_cont  blastdbcmd \
	-db /group/data/blast/nt -entry $seqid \
	-line_length 60 \
	-out refseq_${MID}.fasta
echo TIME map_refseq blastdb end $(date)

echo Header for refseq is : $( grep '^>' refseq_${MID}.fasta )
sed -i '/^>/ s/ .*//g' refseq_${MID}.fasta
echo TIME map_refseq header end $(date)

# alignment (sorted BAM file as final output)
echo TIME map_refseq bbmap start $(date)
$srun_cmd shifter run $bbmap_cont bbmap.sh \
	in=clean.fastq.gz ref=refseq_${MID}.fasta \
	out=mapped_refseq_${MID}_unsorted.sam \
	interleaved=t \
	k=13 maxindel=16000 ambig=random \
	path=ref_${MID} \
	threads=$OMP_NUM_THREADS
echo TIME map_refseq bbmap end $(date)

$srun_cmd shifter run $samtools_cont samtools \
	view -b -o mapped_refseq_${MID}_unsorted.bam mapped_refseq_${MID}_unsorted.sam
echo TIME map_refseq sam view end $(date)

$srun_cmd shifter run $samtools_cont samtools \
	sort -o mapped_refseq_${MID}.bam mapped_refseq_${MID}_unsorted.bam
echo TIME map_refseq sam sort end $(date)

$srun_cmd shifter run $samtools_cont samtools \
	index mapped_refseq_${MID}.bam
echo TIME map_refseq sam index end $(date)

# depth data into text file
$srun_cmd shifter run $samtools_cont samtools \
    depth -aa mapped_refseq_${MID}.bam >depth_refseq_${MID}.dat
echo TIME map_refseq sam depth end $(date)

# creating consensus sequence
$srun_cmd shifter run $bcftools_cont bcftools \
    mpileup -Ou -f refseq_${MID}.fasta mapped_refseq_${MID}.bam \
    | shifter run $bcftools_cont bcftools \
    call --ploidy 1 -mv -Oz -o calls_refseq_${MID}.vcf.gz
echo TIME map_refseq bcf mpileup/call end $(date)

$srun_cmd shifter run $bcftools_cont bcftools \
    tabix calls_refseq_${MID}.vcf.gz
echo TIME map_refseq bcf tabix end $(date)

$srun_cmd shifter run $bcftools_cont bcftools \
    consensus -f refseq_${MID}.fasta -o consensus_refseq_${MID}.fasta calls_refseq_${MID}.vcf.gz
echo TIME map_refseq bcf consensus end $(date)

# copying output data back to group
cp -p $scratch/refseq_${MID}.fasta $scratch/mapped_refseq_${MID}.bam* $scratch/depth_refseq_${MID}.dat $scratch/consensus_refseq_${MID}.fasta $group/
