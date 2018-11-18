## SDH, DPIRD WA

This is a project for porting existing workflows into Zeus on an all-open source software stack.

Science: pathogen genome sequencing from Illumina sequencing reads
Computing: containerisation, workflow automation (bash), porting of input parameters, tuning of multi-threading/memory 
requirements, visualisation tools.

Adaptation of exiting [dpird-mk_GitHub](https://github.com/PawseySC/dpird-mk) workflow

### wf6 - Worlkflow 6 

This workflow is for the assembly, BLAST analysis and mapping of illumina reads for the purpose of diploid pathogen discovery and 
higher organisms. 

Variation on wf1;
	
	- Input		= Interleaved reads via bbmap reformat.sh tool (R1&R2.fastq.gz > interleaved.fastq.gz)
	
	- Assembly 	= dipspades.py for the assembly of diploid organisms
			      	= Careful flag (SPAdes)
	
	- BLAST		= num_alignments 1  
	
Find us on [GitHub](https://github.com/sdhair/dpird-wf/).
