#!/bin/bash
#date: January, 11, 2019, Friedrich-Loeffler-Institut (https://www.fli.de/)

krakenfolder=$1
outputfile=$2

echo -ne "# title: 'Identified species from Kraken2'
# description: 'Number and percentage of reads from first four highest hits by kraken2'
# section: 'Custom Data File'
# format: 'tsv'
# plot_type: 'table'
isolate\t1stMatch\t%1stMatch\t2ndMatch\t%2ndMatch\t3rdMatch\t%3rdMatch\t4thMatch\t%4thMatch\n" > $outputfile


for krakenfile in $(ls $krakenfolder/*.kraken_results_summary.txt); do
cat $krakenfile >> $outputfile;
done
