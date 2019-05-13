## Introduction

A bioinformatics workflow for quick assessment of illumina reads with the focus on (fastqc, species identification, coverage and estimated genome size)     

## Getting Started

### download the project 
* Set up a project folder for the run 
cd /path/to/installation
* Download the latest version from gitlab  
`git clone https://gitlab.com/FLI_Bioinfo/qc_pipeline.git`

### Running the qc_pipeline 
To run the qc_pipeline, run the bash script `checkQC.sh`. Detailed usage is below 

```
bash ./checkQC.sh -h
USAGE:
   bash ./checkQC.sh -d fastq_directory -o Output_directory
REQUIRED:
   -d, --fastq-directory  DIR, a directory where the fastq reads are present
OPTIONAL:
   -l, --linksdir         DIR, a directory to create links for the reads (default: linksdir/)
   -o, --outdir           DIR, an output directory for the snakemake results (default: output/)
   --run [true, false]    Automatically run snakemake (default: true)
   --cores                Number of cores to use (default: available cpus) 
   --kraken2              Path to (Mini)kraken2 DB. You may download ftp://ftp.ccb.jhu.edu/pub/data/kraken2_dbs/minikraken2_v2_8GB_201904_UPDATE.tgz
   -h, --help             This help
```

* As input for `checkQC.sh`, you need to use the folder where the fastq files are present with option `-d`. In standard cases, fastq files could have any of the following format (sampleID\_S3\_L001\_R1_001.fastq.gz, sampleID\_1.fastq.gz, sampleID\_1.fq.gz, sampleID\_1.fq .gz), could also be uncompressed.   
* The script `checkQC.sh` creates a new folder where links for the samples are created "option `-l`". In this folder the name of samples is corrected to be read with snakemake in this format "sampleID\_1.fastq.gz"   
* Additionally, `checkQC.sh` writes a config file updated with paths to output folder "option `-o`", kraken2 DB "option `--kraken2`" and snakemake "default is the current folder"   
* snakemake runs automatically "option `--run true`" with the cores "option `--cores`". However, the automatic run could be deactivated using `--run false`. In this case you need to run snakemake in a separate step.   

#### Example  

`bash ./checkQC.sh -d /path/to/inputfolder -o /path/to/outputfolder --run true --cores 64 --kraken2 /home/DB_RAM/kraken2`  

## Authors    
Mostafa Abdel-Glil (mostafa.abdel-glil@fli.de)  
Jörg Linde (joerg.linde@fli.de)  

## Contributors   

