#!/bin/bash

#add arguments to the script
myinpudirectory=$1


cd $myinpudirectory

for R1 in `ls *R1_001.fastq.gz` 

do

    R2=${R1//R1_001.fastq.gz/R2_001.fastq.gz}
    R1paired=${R1//.fastq.gz/_paired.fastq.gz}
    R1unpaired=${R1//.fastq.gz/_unpaired.fastq.gz}	
    R2paired=${R2//.fastq.gz/_paired.fastq.gz}
    R2unpaired=${R2//.fastq.gz/_unpaired.fastq.gz}	
   
	java -jar /data/projects/p529_ABERRANT/software/Trimmomatic-0.39/trimmomatic-0.39.jar PE -threads 25 -phred33 $R1 $R2 $R1paired $R1unpaired $R2paired $R2unpaired ILLUMINACLIP:/data/projects/p529_ABERRANT/software/Trimmomatic-0.39/adapters/NexteraPE-PE_sleo.fa:2:30:10 SLIDINGWINDOW:20:28 MINLEN:100
	
done
