# Eczema
Script used for metagenomic analyses

1. pre_processing_analyses.sbatch contains all the commands used in the pre-processing of reads. This includes: quality-filtering and trimming, the removal of human DNA and the taxonomic classification with Kraken2/Bracken and MetaPhlAn 3.

2. trimm_fastq.sh contains the command lines and settings for Trimmomatic. This is integrated in the pre_processing_analyses.sbatch script.
