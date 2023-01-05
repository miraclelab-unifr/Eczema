#!/bin/bash

#SBATCH --cpus-per-task=50
#SBATCH --mem=499G
#SBATCH --time=100:00:00
#SBATCH --job-name="misbr"
#SBATCH --mail-user=none
#SBATCH --mail-type=begin,end,fail


#Forward and Reverse FASTQ files for each sample are generated for each of the 4 lanes of the Illumina Sequencer.
#Thus, each sample has 8 FASTQ files, four from forward and four from reverse reads 

#add modules

module add UHTS/Quality_control/fastqc/0.11.7
module add UHTS/Analysis/braken/2.6.2

#Create folders to collect outputs of quality-filtering and inspection of the quality of the reads (pre and post Trimmomatic)

mkdir /data/projects/p529_ABERRANT/projects/misbair
mkdir /data/projects/p529_ABERRANT/projects/misbair/trim/

mkdir /data/projects/p529_ABERRANT/projects/misbair/fastqc
mkdir /data/projects/p529_ABERRANT/projects/misbair/fastqc/pretrim/
mkdir /data/projects/p529_ABERRANT/projects/misbair/fastqc/post_trim/

#Quality check of raw reads
cd /data/projects/p529_ABERRANT/raw_data/misbair

for R1 in `ls *R1_001.fastq.gz` 

do
    R2=${R1//R1_001.fastq.gz/R2_001.fastq.gz}
         
fastqc  ./$R1 -o /data/projects/p529_ABERRANT/projects/misbair/fastqc/pretrim/ --threads 25
fastqc  ./$R2 -o /data/projects/p529_ABERRANT/projects/misbair/fastqc/pretrim/ --threads 25
			
 done

#Run trimmomatic
#trimm_fastq.sh is attached in the Github folder 

cd /data/projects/p529_ABERRANT/projects/

bash /data/projects/p529_ABERRANT/projects/script/trimm_fastq.sh /data/projects/p529_ABERRANT/raw_data/misbair/ 

# Move paired trimmed reads and unpaired ones in different folders

mv /data/projects/p529_ABERRANT/raw_data/misbair/*_paired.fastq.gz /data/projects/p529_ABERRANT/projects/misbair/trim/
mkdir /data/projects/p529_ABERRANT/projects/misbair/trim/unpaired
mv /data/projects/p529_ABERRANT/raw_data/misbair/*_unpaired.fastq.gz /data/projects/p529_ABERRANT/projects/misbair/trim/unpaired/

#inspect quality of the reads after Trimmomatic 

cd /data/projects/p529_ABERRANT/projects/misbair/trim/

for R1 in `ls *R1_001_paired.fastq.gz` 

do
    R2=${R1//R1_001_paired.fastq.gz/R2_001_paired.fastq.gz}
 
	fastqc  ./$R1 -o /data/projects/p529_ABERRANT/projects/misbair/fastqc/post_trim/ --threads 25
	fastqc  ./$R2 -o /data/projects/p529_ABERRANT/projects/misbair/fastqc/post_trim/ --threads 25

done

#Concatenate reads from different lanes

mkdir /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/

 cd /data/projects/p529_ABERRANT/projects/misbair/trim/

#Collect names of the FASTQ files containing reads from the first lane from each sample
 for file in `ls *_L001_R1_001_paired.fastq.gz`  
 do
 samplename=${file%%_L001_R1_001_paired.fastq.gz}""
 echo $samplename >> samples.txt
 done
 
#Show head samples.txt file
head samples.txt
# 3126D7_S1
# 3159D7_S1
# 3182D5_S2
# 3189D7_S1
# 3200D6_S3
# 3201D7_S2
# 3202D7_S4
# 3222D7_S9
# 3233D7_S1
# 3234D7_S5
 

 
 cd /data/projects/p529_ABERRANT/projects/misbair/trim/
 
 for file in `cat samples.txt` 
 do

#do for forward reads (R1)
  myR1="$(ls | grep $file | grep "R1")"

  mkdir /data/projects/p529_ABERRANT/projects/misbair/trim/temp/ 
  cp $myR1 /data/projects/p529_ABERRANT/projects/misbair/trim/temp/ 
  cd /data/projects/p529_ABERRANT/projects/misbair/trim/temp/
  gunzip *fastq.gz
  myfiles="$(ls *fastq)"
  cat $myfiles > $file"_R1_001.fastq"

#for a matter of space, FASTQ files were zipped
  gzip $file"_R1_001.fastq"
  mv $file"_R1_001.fastq.gz" /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/

  rm -r /data/projects/p529_ABERRANT/projects/misbair/trim/temp

#do for reverse reads (R2)

 cd /data/projects/p529_ABERRANT/projects/misbair/trim/

 myR2="$(ls | grep $file | grep "R2")"

  mkdir /data/projects/p529_ABERRANT/projects/misbair/trim/temp 
  cp $myR2 /data/projects/p529_ABERRANT/projects/misbair/trim/temp 
 
 cd /data/projects/p529_ABERRANT/projects/misbair/trim/temp 
  gunzip *fastq.gz
  myfiles="$(ls *fastq)" 
  cat $myfiles > $file"_R2_001.fastq"

#for a matter of space, FASTQ files were zipped
  gzip $file"_R2_001.fastq"
  mv $file"_R2_001.fastq.gz" /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/

  rm -r /data/projects/p529_ABERRANT/projects/misbair/trim/temp

  cd /data/projects/p529_ABERRANT/projects/misbair/trim/

 done

#########################################################################################################################

# Classify to human and phi 174 reads by kraken - confidence 0.1

 mkdir /data/projects/p529_ABERRANT/projects/misbair/kraken/
 mkdir /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/
 mkdir /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/report


 cd /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines

 for R1gz in `ls *R1_001.fastq.gz` 

  do

  R2gz=${R1gz//R1_001.fastq.gz/R2_001.fastq.gz}

  samplename=${R1gz%%R1_001.fastq.gz}""

# # #create a temporary file where to store the unzip files
  mkdir /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp
  cp ./$R1gz /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp
  cp ./$R2gz /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp

 cd /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp
 gunzip ./$R1gz
 gunzip ./$R2gz

# create names for unzip files
  R1=${R1gz//R1_001.fastq.gz/R1_001.fastq}
  R2=${R1gz//R1_001.fastq.gz/R2_001.fastq}

  cd /data/projects/p529_ABERRANT/software/kraken2-master/

# generate with Kraken2 FASTQ files containing no human reads

  ./kraken2 --db /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_human_phi/ --paired /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp/$R1 /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp/$R2 --use-names --use-mpa-style --report /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/report/$samplename"_report" --unclassified-out /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/"no_human_"$samplename"#.fastq" --confidence 0.1 --threads 20
  ./kraken2 --db /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_human_phi/ --paired /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp/$R1  /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp/$R2 --use-names --report /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/report/$samplename"_fullreport" --confidence 0.1 --threads 20

  rm -r /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/temp/

  cd /data/projects/p529_ABERRANT/projects/misbair/trim/merged_lines/

  done

#########################################################################################################################

#classify to bacterial, fungal, viral reads by kraken - confidence 0.1

mkdir /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/
mkdir /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/reads_assignment/

cd /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/

for R1 in `ls no_human_*_1.fastq` 

do

 R2=${R1//_1.fastq/_2.fastq}
 samplename=${R1%%_1.fastq}""

cd /data/projects/p529_ABERRANT/software/kraken2-master/

 ./kraken2 --db /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf --paired /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/$R1 /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/$R2 --use-names --use-mpa-style --report /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/$samplename"_report" --confidence 0.1 --threads 15 > /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/reads_assignment/$samplename"_read_assign"
 ./kraken2 --db /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf --paired /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/$R1 /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/$R2 --use-names --report /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/$samplename"_fullreport" --confidence 0.1 --threads 15 >  /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/reads_assignment/$samplename"_read_assign_copy"

cd /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/

 done


 ######################################################################################################
 ######################################################################################################
 
 #run Bracken
 
# Step #1a: Search all library input sequences against the database using:

/data/projects/p529_ABERRANT/software/kraken2-master/kraken2 --db /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf --threads 99 <( find -L /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/library/added \( -name *.fna -o -name *.fa -o -name *.fasta \) -exec cat {} + ) > /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database.kraken

cd /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/

#delete row containing info for NC_017829.1 - Cotton leaf curl virus betasatellite, complete genome
 cat database.kraken | grep "NC_017829.1" -v > database_clean.kraken

# ------------------------------------------------------------------------
#Step #1b: Compute the classifications for each perfect read of ${READ_LENGTH} base pairs from one of the input sequences.

kmer2read_distr --seqid2taxid /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/seqid2taxid.map --taxonomy /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/taxonomy/ --kraken /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database_clean.kraken --output /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken -k 35 -l 100 -t 99

# ------------------------------------------------------------------------
#Step #1c: Generate kmer distribution file from the.

# cd /mnt/software/UHTS/Analysis/braken/2.6.2/bin
python ./generate_kmer_distribution.py -i /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken -o /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken_distrib 


#run Bracken on Kraken2 output

mkdir /data/projects/p529_ABERRANT/projects/misbair/bracken/

cd /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/

for report in `ls *__fullreport` 

 do

 samplename=${report%%__fullreport}""
 
#run bracken 
cd /mnt/software/UHTS/Analysis/braken/2.6.2/bin

#species level
python ./est_abundance.py -i /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/$report -k /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken_distrib -o /data/projects/p529_ABERRANT/projects/misbair/bracken/$samplename"_noconf.bracken" -l 'S' -t 10

#genus
python ./est_abundance.py -i /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/$report -k /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken_distrib -o /data/projects/p529_ABERRANT/projects/misbair/bracken/$samplename"_noconf_genus.bracken" -l 'G' -t 10

#family
python ./est_abundance.py -i /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/$report -k /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken_distrib -o /data/projects/p529_ABERRANT/projects/misbair/bracken/$samplename"_noconf_family.bracken" -l 'F' -t 10

#phylum
python ./est_abundance.py -i /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/$report -k /data/projects/p529_ABERRANT/software/kraken2-master/KrakenDB_bvf/database100mers_no_confidence_clean.kraken_distrib -o /data/projects/p529_ABERRANT/projects/misbair/bracken/$samplename"_noconf_phylum.bracken" -l 'P' -t 10

cd /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/

done
 
cp /data/projects/p529_ABERRANT/projects/misbair/kraken/bac_vir_fung/*__report /data/projects/p529_ABERRANT/projects/misbair/bracken/
 
  ######################################################################################################
 ######################################################################################################
 
 #run MetaPhlAn 3 operated with singularity
 
mkdir /data/projects/p529_ABERRANT/projects/misbair/metaphlan/

cd /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/

  for R1 in `ls no_human_*_1.fastq` 

   do

  R2=${R1//_1.fastq/_2.fastq}
  samplename=${R1%%_1.fastq}""
 
  cd /data/projects/p529_ABERRANT/projects/
 
 singularity exec --bind /db/SOFTWARE/MetaPhlAn/,/data/projects/p529_ABERRANT/projects/misbair/ /software/singularity/containers/MetaPhlAn-3.0.7-1.ubuntu20.sif metaphlan $PWD/misbair/kraken/nohuman/$R1,$PWD/misbair/kraken/nohuman/$R2 -o $PWD/misbair/metaphlan/"results_"$samplename".txt" -s $PWD/misbair/metaphlan/"results_sam_"$samplename".sam.bz2" --bowtie2out $PWD/misbair/metaphlan/"results_bowtie_"$samplename".bz2"  --nproc 30 --input_type fastq

  cd /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/
  
   done


# re-arrange results and merge tables

cd /data/projects/p529_ABERRANT/projects/misbair/metaphlan

 mkdir /data/projects/p529_ABERRANT/projects/misbair/metaphlan/sam
 mkdir /data/projects/p529_ABERRANT/projects/misbair/metaphlan/bowtie
 mkdir /data/projects/p529_ABERRANT/projects/misbair/metaphlan/counts

 mv results_sam*.sam.bz2 /data/projects/p529_ABERRANT/projects/misbair/metaphlan/sam
 mv results_bowtie*_.bz2 /data/projects/p529_ABERRANT/projects/misbair/metaphlan/bowtie
 mv results_nb_sam_*.sam.bz2 /data/projects/p529_ABERRANT/projects/misbair/metaphlan/sam
 mv results_nb_bowtie*_.bz2 /data/projects/p529_ABERRANT/projects/misbair/metaphlan/bowtie
 mv results_nb_no_human_*txt /data/projects/p529_ABERRANT/projects/misbair/metaphlan/counts


singularity exec --bind /db/SOFTWARE/MetaPhlAn/,/data/projects/p529_ABERRANT/projects/misbair/ /software/singularity/containers/MetaPhlAn-3.0.7-1.ubuntu20.sif merge_metaphlan_tables.py $PWD/misbair/metaphlan/results_no_human*.txt > $PWD/misbair/metaphlan/merged_abundance_table.txt


 
 
 
 
 
 
 