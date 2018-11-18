#!/bin/bash -l

#SBATCH --job-name=align_AIDNUM
#SBATCH --output=%x.out
#SBATCH --account=director2091
#SBATCH --clusters=zeus
#SBATCH --partition=workq
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem=50G
#SBATCH --export=NONE 
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

AID="AIDNUM"

# sample id and working directories
sample="test1"
group="/group/director2091/mdelapierre/illumina/test1"
scratch="/scratch/director2091/mdelapierre/illumina/test1"

# shifter definitions
module load shifter
srun_cmd="srun --export=all"
mafft_cont="quay.io/biocontainers/mafft:7.407--0"


# copying input data to scratch
cd $group
for f in consensus_contigs_sub.fasta $(ls consensus_contig_*.fasta 2>/dev/null) $(ls consensus_refseq_*.fasta 2>/dev/null) ; do
 if [ ! -f $scratch/$f ] ; then
  cp -p $group/$f $scratch/
 fi
done

# running
cd $scratch
echo Group directory : $group
echo Scratch directory : $scratch
echo SLURM job id : $SLURM_JOB_ID

contig_list="NODE_1"
refseq_list="HG970869.1"
echo align run number : ${AID}

# extracting consensus contig(s) from entire set
echo TIME align contig start $(date)
contig_files=$(ls consensus_contig_*.fasta 2>/dev/null)
contig_num=$(echo $contig_files | wc -w)
for id in $contig_list ; do
 found=0
 for file in $contig_files ; do
  found=$(grep -c ">$id" $file)
  if [ "$found" == "1" ] ; then
   consensus_contig_list+=" $file"
   break
  fi
 done
 if [ "$found" == "0" ] ; then
  : $((++contig_num))
  consensus_contig_list+=" consensus_contig_${contig_num}.fasta"
  awk -F _ -v id=${id#NODE_} '{ if(ok==1){if($1==">NODE"){exit}; print} ; if(ok!=1 && $1==">NODE" && $2==id){ok=1; print} }' consensus_contigs_sub.fasta >consensus_contig_${contig_num}.fasta
 fi
done
echo align list of contig IDs : ${contig_list}
echo align list of contig files : ${consensus_contig_list}
echo TIME align contig end $(date)

# building list of refseq(s)
refseq_files=$(ls consensus_refseq_*.fasta 2>/dev/null)
for id in $refseq_list ; do
 found=0
 for file in $refseq_files ; do
  found=$(grep -c ">$id" $file)
  if [ "$found" == "1" ] ; then
   consensus_refseq_list+=" $file"
   break
  fi
 done
 if [ "$found" == "0" ] ; then
  echo ERROR : refseq ID $id not found in existing consensus_refseq FASTA files.
  echo "Re-run refseq mapping for that ID (step 06) and try again."
  echo Exiting now.
  exit
 fi
done
echo align list of refseq IDs : ${refseq_list}
echo align list of refseq files : ${consensus_refseq_list}
echo TIME align refseq end $(date)

# building fasta input for mafft
cat $consensus_refseq_list $consensus_contig_list >input_align_${AID}.fasta
echo TIME align concat end $(date)

# multiple alignment of selected consensus sequences
$srun_cmd shifter run $mafft_cont mafft-linsi \
	--thread $OMP_NUM_THREADS \
	input_align_${AID}.fasta >aligned_${AID}.fasta
echo TIME align mafft end $(date)

# copying output data back to group
cp -p $scratch/consensus_contig_*.fasta $scratch/input_align_${AID}.fasta $scratch/aligned_${AID}.fasta $group/
