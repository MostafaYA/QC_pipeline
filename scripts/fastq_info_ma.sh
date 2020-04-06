#!/bin/bash
#dependencies
#mash
#seqkit
fastq1=$1  #fastq input 1
fastq2=$2  #fastq input 2
#fasta=$3 #fasta input
mashfile=$(mktemp)

total_seq_read1=$(seqkit stats $fastq1 | awk 'NR==2{print $5}' | sed -e 's/,//g')
total_seq_read2=$(seqkit stats $fastq2 | awk 'NR==2{print $5}' | sed -e 's/,//g')
total_seq=$(echo "$total_seq_read1+$total_seq_read2"|bc) #calculate total read length

total_number_read1=$(seqkit stats $fastq1 | awk 'NR==2{print $4}' | sed -e 's/,//g')
total_number_read2=$(seqkit stats $fastq2 | awk 'NR==2{print $4}' | sed -e 's/,//g')
total_reads=$(echo "$total_number_read1+$total_number_read2"|bc) #calculate total read length


mash sketch -o $(mktemp) -k 32 -m 3 -r $fastq1 &> $mashfile
genomesize=$(egrep -Eo 'Estimated genome size:.{1,50}' $mashfile | cut -d " " -f 4- |  perl -ne 'printf "%d\n", $_;')

coverage=$(echo "$total_seq/$genomesize"|bc)

filenameshort=$(basename -- "$fastq1")
filenameshort2=$(basename -- "$fastq2")
#filenameshort_ref=$(basename -- "$fasta")



#To print the tab-delimited table on standard output
echo -n -e "File R1\t"
echo -n -e "File R2\t"
#echo -n -e "Reference Genome\t"
echo -n -e "Total sequences\t"
echo -n -e "Total reads\t"
echo -n -e "Estimated genome size\t"
echo -e "Estimated coverage"
echo -n -e "$filenameshort\t"
echo -n -e "$filenameshort2\t"
#echo -n -e "$filenameshort_ref\t"
echo -n -e "$total_seq\t"
echo -n -e "$total_reads\t"
echo -n -e "$genomesize\t"
echo -e "$coverage"


exit 0;
