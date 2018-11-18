#!/bin/bash

# project id
account=director2091

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


# SLURM script names
script_map_refseq="06.map_refseq_MID.sh"
script_align="07.align_AID.sh"
# input file name(s)
read_file="clean.fastq.gz"
# prefix/suffix of map_refseq consensus output files
prefix_map="consensus_refseq"
suffix_map="fasta"


# check for command arguments
if [ $# -eq 0 ] ; then
 echo "There are two usage modes for this script."
 echo "1. Map reads to a set of reference sequences; "
 echo "   as argument, provide at least one refseq ID (from the BLAST output)."
 echo "2. Map reads to ref. sequences, then perform multiple alignment between those and a set of contig sequences; "
 echo "   as argument, provide at least one refseq ID (from the BLAST output) and one contig ID (from the assembled contigs file)."
 echo "No arguments provided. Exiting."
 exit
fi

# check for read files
if [ ! -s $read_file ] ; then
 echo "Input read file $read_file is missing. Exiting."
 exit
fi

# apply definitions above in SLURM script files
list_script+="${script_map_refseq/_MID/_*}"
list_script+=" ${script_align/_AID/_*}"
sed -i "s;#SBATCH --account=.*;#SBATCH --account=$account;g" $list_script
sed -i "s;^ *sample=.*;sample=\"$sample\";g" $list_script
sed -i "s;^ *group=.*;group=\"$group\";g" $list_script
sed -i "s;^ *scratch=.*;scratch=\"$scratch\";g" $list_script

# create scratch
mkdir -p $scratch

echo Group directory : $group
echo Scratch directory : $scratch

# classify input arguments
arg_list="$@"
ref_list=$(echo $arg_list | xargs -n 1 | grep -v NODE | xargs)
ref_num=$( echo $ref_list | wc -w)
con_list=$(echo $arg_list | xargs -n 1 | grep NODE | xargs)
con_num=$( echo $con_list | wc -w)
if [ $ref_num -eq 0 ] ; then
 echo "At least one refseq ID (from the BLAST output) is required. Exiting."
 exit
fi

# generate required refseq SLURM scripts
refseq_files=$(ls ${prefix_map}_*.${suffix_map} 2>/dev/null)
refseq_num=$(echo $refseq_files | wc -w)
new_num=0
for id in $ref_list ; do
 found=0
 for file in $refseq_files ; do
  found=$(grep -c ">$id" $file)
  if [ "$found" == "1" ] ; then
   break
  fi
 done
 if [ "$found" == "0" ] ; then
  : $((++new_num))
  newid=$((refseq_num+new_num))
  sed -e "s/MIDNUM/$newid/g" -e "s/seqid=.*/seqid=${id}/g" $script_map_refseq >${script_map_refseq/_MID/_$newid}
 fi
done

# prepare SLURM script for multiple alignment (if applicable)
if [ $con_num -gt 0 ] ; then
 align_num=$(ls ${script_align/_AID/_[0-9]*} 2>/dev/null | wc -w)
 alid=$((++align_num))
 sed -e "s/AIDNUM/$alid/g" \
  -e "s/refseq_list=.*/refseq_list=\"${ref_list}\"/g" \
  -e "s/contig_list=.*/contig_list=\"${con_list}\"/g" \
  $script_align >${script_align/_AID/_$alid}
fi

# workflow of job submissions
# maps to refseq
if [ $new_num -gt 0 ] ; then
 for (( i=1 ; i <= $new_num ; i++ )) ; do
  newid=$((refseq_num+i))
  jobid_map_refseq=$( sbatch --parsable                                   ${script_map_refseq/_MID/_$newid} | cut -d ";" -f 1 )
  list_jobid+=:$jobid_map_refseq
  echo Submitted script ${script_map_refseq/_MID/_$newid} with job ID $jobid_map_refseq
 done
fi
# multiple alignment (if applicable)
if [ $con_num -gt 0 ] ; then
 if [ $new_num -gt 0 ] ; then
  jobid_align=$(      sbatch --parsable --dependency=afterok"$list_jobid" ${script_align/_AID/_$alid}       | cut -d ";" -f 1 )
 else
  jobid_align=$(      sbatch --parsable                                   ${script_align/_AID/_$alid}       | cut -d ";" -f 1 )
 fi
 echo Submitted script ${script_align/_AID/_$alid} with job ID $jobid_align
fi
