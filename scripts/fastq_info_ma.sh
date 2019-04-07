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

mash sketch -o $(mktemp) -k 32 -m 3 -r $fastq1 &> $mashfile
genomesize=$(egrep -Eo 'Estimated genome size:.{1,50}' $mashfile | cut -d " " -f 4- |  perl -ne 'printf "%d\n", $_;')

coverage=$(echo "$total_seq/$genomesize"|bc)
#To calculate average read length
#readlength1=$(awk 'NR % 4 == 2 { s += length($1); t++} END {print s/t}' $fastq1) #calculate read length for fastq file 1
#readlength2=$(awk 'NR % 4 == 2 { s += length($1); t++} END {print s/t}' $fastq2) #calculate read length for fastq file 2
#totalreadlength=$(echo "$readlength1+$readlength2"|bc) #calculate total read length
#averagereadlength=$(echo "$totalreadlength/2"|bc) #calculate average read length by parsing into bc command - which truncates the decimal numbers by default in multiplication/division

#To calculate readcount
#readcount1=$(zcat $fastq1| echo $((`wc -l`/4))) #read count in file 1
#readcount2=$(zcat $fastq2| echo $((`wc -l`/4))) #read count in file 2
#totalreadcount=$(echo "$readcount1+$readcount2"|bc) #total read count of file 1 and file 2
#averagereadcount=$(echo "$totalreadcount/2"|bc) #average read count - parsed into bc command to be rounded

#totalseq=$(echo "$totalreadcount*$readcount2"|bc)

#To calculate genome size
#awk '!/^>/ { printf "%s", $0; n = "\n" } /^>/ { print n $0; n = "" } END { printf "%s", n }' $fasta > "$fasta"-single
#cat "$fasta"-single|awk 'NR%2==0'| awk '{print length($1)}' > "$fasta"-oneline
#genomesize=$(awk '{ sum += $1 } END { print sum }' "$fasta"-oneline)

#estimate the genome size

#To calculate actual sequencing depth/coverage
#sequencing depth= LN/G =average read length * average reads / genome size
#LN=$(echo "$averagereadcount*$averagereadlength*2")
#G=$genomesize
#coverage=$(echo "$LN/$G"|bc)

filenameshort=$(basename -- "$fastq1")
filenameshort2=$(basename -- "$fastq2")
#filenameshort_ref=$(basename -- "$fasta")



#To print the tab-delimited table on standard output
echo -n -e "File R1\t"
echo -n -e "File R2\t"
#echo -n -e "Reference Genome\t"
#echo -n -e "average_read_length\t"
echo -n -e "Total seq\t"
echo -n -e "genome\t"
echo -e "coverage"
echo -n -e "$filenameshort\t"
echo -n -e "$filenameshort2\t"
#echo -n -e "$filenameshort_ref\t"
#echo -n -e "$averagereadlength\t"
echo -n -e "$total_seq\t"
echo -n -e "$genomesize\t"
echo -e "$coverage"

#To remove intermediary files (due to the size, these files cannot be parsed into variables)
#rm "$fasta"-single;
#rm "$fasta"-oneline;

exit 0;
