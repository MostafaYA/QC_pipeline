#!/bin/bash
#date: January, 11, 2019, Friedrich-Loeffler-Institut (https://www.fli.de/)

fastpfolder=$1
outputfile=$2
tsv_outputfile=$3

echo -ne "# title: 'FASTQ quality results'
# description: ''
# section: 'Custom Data File'
# format: 'tsv'
# plot_type: 'table'
Isolate\tTotal reads\tTotal bases\tQ20 bases\tQ30 bases\tGC content\n" > $outputfile


for fastpfile in $(ls $fastpfolder/*.fastp_results_summary.txt); do
cat $fastpfile >> $outputfile;
echo -ne "Isolate\tTotal reads\tTotal bases\tQ20 bases\tQ30 bases\tGC content\n" > $tsv_outputfile;
cat $fastpfile >> $tsv_outputfile;
done
