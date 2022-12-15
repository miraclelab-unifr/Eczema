#!/bin/bash

#SBATCH --cpus-per-task=100
#SBATCH --mem=499G
#SBATCH --mail-user=none
#SBATCH --mail-type=begin,end,fail

 module add Conda/miniconda/latest

#Copy quality-filtered non-human read FASTQs and combine R1 and R2 in one unique file.

 mkdir /data/projects/p529_ABERRANT/projects/misbair/humann/

cd /data/projects/p529_ABERRANT/projects/misbair/kraken/nohuman/

  for R1 in `ls no_human_*__1.fastq` 

   do

  R2=${R1//_1.fastq/__2.fastq}
  samplename=${R1%%__1.fastq}""
 
 ##cut R1 and R2 together
 
 cat $R1 $R2 > $samplename"_R1_R2.fastq"
 
 mv $samplename"_R1_R2.fastq" /data/projects/p529_ABERRANT/projects/misbair/humann/
 
 done
 
 
 #run humann
 

 cd /data/projects/p529_ABERRANT/projects/misbair/humann/
 
 mkdir /data/projects/p529_ABERRANT/projects/misbair/humann/final_results
 
   for R1 in `ls no_human_*_R1_R2.fastq` 

   do
   
     samplename=${R1%%_R1_R2.fastq}""
 
    humann -i /data/projects/p529_ABERRANT/projects/misbair/humann/$R1 --output /data/projects/p529_ABERRANT/projects/misbair/humann/$samplename"_results_prot" --protein-database  /data/projects/p529_ABERRANT/projects/misbair/humann/protein_db/ --bypass-prescreen --bypass-nucleotide-search --threads 100

	mv /data/projects/p529_ABERRANT/projects/misbair/humann/$samplename"_results_prot"/*tsv /data/projects/p529_ABERRANT/projects/misbair/humann/final_results
	
	done
 

 #normalize RKPs
 mkdir /data/projects/p529_ABERRANT/projects/misbair/humann/final_norm_results
 
 cd /data/projects/p529_ABERRANT/projects/misbair/humann/final_results
 
  for R1 in `ls *_R1_R2_pathabundance.tsv`
  do

samplename=${R1%%_R1_R2_pathabundance.tsv}""  
  
 humann_renorm_table --input $R1 --output /data/projects/p529_ABERRANT/projects/misbair/humann/final_norm_results/$samplename"_R1_R2_pathabundance-cpm.tsv" --units cpm --update-snames
 
done
 

##################################

#run R script to merge tables

# module add R
# setwd("/data/projects/p529_ABERRANT/projects/misbair/humann/final_norm_results")
# #read files present in the folder and select reports 
# files  <- list.files(full.names = TRUE)

# #create a list of sample names
# samplenames <- as.character(unlist(sapply(files , function(x) gsub("\\./","",x ))))
# samplenames <- as.character(unlist(sapply(samplenames, function(x) gsub("\\_R1_R2_pathabundance-cpm.tsv","",x ))))
# samplenames <- as.character(unlist(sapply(samplenames, function(x) gsub("no_human_","",x ))))

# #label for  "3778D6-2_S30" already good
# #create a table with infos about reports and samples
# mytablesamples= as.data.frame(matrix(NA, nrow= length(samplenames),
                                     # ncol =2))

# colnames(mytablesamples)= c("SampleID", "file")

# for(i in 1:length(samplenames)){
  
  # mytablesamples[i,"SampleID"] = samplenames[i]
  # mytablesamples[i,"file"] = as.character(files[grep(samplenames[i], files)])
# }

# rm(i)

# #read first file

# mytab = read.delim(mytablesamples[1,2], sep ="\t", skip =1, header =FALSE)

# colnames(mytab) = c("pathway", mytablesamples[1,1])

# for(q in 2:nrow(mytablesamples)){

# mytab.q = read.delim(mytablesamples[q,2], sep ="\t", skip =1, header =FALSE)
# colnames(mytab.q) = c("pathway", mytablesamples[q,1])
# #merge

# mytab = merge(mytab, mytab.q, by ="pathway", all = TRUE, sort = FALSE)
# }

# write.csv(mytab,"pathway_abund_cpm.csv",row.names = FALSE)














 
