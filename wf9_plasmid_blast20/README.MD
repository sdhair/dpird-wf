## SDH, DPIRD WA

This is a project for porting existing workflows into Zeus on an all-open source software stack.

Science: pathogen genome sequencing from Illumina sequencing reads
Computing: containerisation, workflow automation (bash), porting of input parameters, tuning of multi-threading/memory 
requirements, visualisation tools.

Adaptation of exiting [dpird-mk_GitHub](https://github.com/PawseySC/dpird-mk) workflow


### wf9 - Worlkflow 9 

This workflow is for the assembly, BLAST analysis and mapping of illumina reads for the purpose of assembling and detecting plasmids (and potentially mitochondrial genomes). 

Variation on wf1
<<<<<<< HEAD:wf9_plasmid_blast20/README.MD

	- Input		= Interleaved reads via the bbmap reformat.sh tool (R1&R2.fastq.gz > interleaved.fastq.gz)

	- Assembly 	= Careful flag (SPAdes)
              = Plasmid flag (SPAdes) 

=======
	
	- Input		= Interleaved reads via the bbmap reformat.sh tool (R1&R2.fastq.gz > interleaved.fastq.gz)
	
	- Assembly 	= Careful flag (SPAdes)
	
>>>>>>> 19313230ec0ab4df810a147a6a290d8d4aae2561:workflow_5/README.MD
	- BLAST		= num_alignments 20   

Find us on [GitHub](https://github.com/sdhair/dpird-wf/).
