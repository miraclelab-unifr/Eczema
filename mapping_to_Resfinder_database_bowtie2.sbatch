#!/bin/bash

#SBATCH --cpus-per-task=50
#SBATCH --mem=100G
#SBATCH -t 14-0:00


module add UHTS/Aligner/bowtie2/2.3.1
module add UHTS/Analysis/samtools/1.10
module load UHTS/Analysis/BEDTools/2.29.2
 
 cd /data/projects/p529_ABERRANT/projects/misbair/bowtie2

#build database from deduplicated ResFinder sequences
 bowtie2-build all_noDup.fa all_noDup_index

 cd /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/


for R1 in `ls no_human_*_1.fastq` 

 do

 R2=${R1//_1.fastq/_2.fastq}
 samplename=${R1%%_1.fastq}""

bowtie2 -D 20 -R 3 -N 1 -L 20 -i S,1,0.50 -x /data/projects/p529_ABERRANT/projects/misbair/bowtie2/all_noDup_index -1 $R1 -2 $R2 -S /data/projects/p529_ABERRANT/projects/misbair/bowtie2/$samplename"final.sam" --threads 100

done

#convert sam files in bam files 


mkdir /data/projects/p529_ABERRANT/projects/misbair/bowtie2/bam_files/
cd /data/projects/p529_ABERRANT/projects/misbair/bowtie2/


for file in `ls no_human_*_final.sam` 

 do

 samplename=${file%%.sam}""

samtools view -S -b $file > $samplename".bam"
samtools sort $samplename".bam" -o $samplename".sorted.bam"
samtools index $samplename".sorted.bam"

done

#move all bam files in the corresponding directory

mv /data/projects/p529_ABERRANT/projects/misbair/bowtie2/*bam /data/projects/p529_ABERRANT/projects/misbair/bowtie2/bam_files/
mv /data/projects/p529_ABERRANT/projects/misbair/bowtie2/*bam.bai /data/projects/p529_ABERRANT/projects/misbair/bowtie2/bam_files/

#Sam files were removed for a matter of space

#Obtain read count tables
#For this step a bed file containf the length of the sequences is needed

cd /data/projects/p529_ABERRANT/projects/misbair/bowtie2
#resfindergenes.bed is needed, it is a tab-delim file with first column = genename, second column = 1, third column = length of the gene
cat all_noDup.fa | awk '$0 ~ "^>" {name=substr($0, 2); printf name"\t1\t"} $0 !~ "^>" {printf length($0)"\t"name"\n"}' > all_noDup.bed 

cd /data/projects/p529_ABERRANT/projects/misbair/bowtie2/bam_files/

BAMLIST=`ls *.sorted.bam`

echo $BAMLIST > my_colnames_bam

#copy bed file
cp /data/projects/p529_ABERRANT/projects/misbair/bowtie2/all_noDup.bed /data/projects/p529_ABERRANT/projects/misbair/bowtie2/bam_files/

# gives the table of counts for ONLY properly paired reads UNIQUELY mapped (MAPQ > 1) in each bam and each gene (no multimapping reads)
bedtools multicov -p -q 1 -bams $BAMLIST -bed all_noDup.bed > only_paired_mapped_no_multiple_mapping_reads




