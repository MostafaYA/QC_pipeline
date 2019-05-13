#!/bin/bash
#date: January, 11, 2019, Friedrich-Loeffler-Institut (https://www.fli.de/)


report=$1
temporaryfile=$(mktemp)
#fore each file
for i in $report; do
#remove path take only filename
	j=$(basename $i);
#remove ".txt" output sample name
	echo -ne ${j%.report.txt}'\t';
#take only columns with S (species) and U (unspecified)
#sort decending by number of reads
#sort first 4 (head -n4) elements
	awk -F "\t" '{ if ($4 == "S" || $4 == "U") { print $0} }' $i | sort --key 1 --numeric-sort --reverse  | head -n 4 | awk '{ print $1,$6 }' FS="\t" OFS="," |\
		  while read line ; do
		#	echo -n $line;
			PERCENT=$(echo $line | awk '{ print $1 }' FS="," );
			SPECIES=$(echo $line | awk '{print $2}' FS=",");
#output
			res=$SPECIES'\t'$PERCENT'\t';
			#echo -n -e   "${res::-1}";
				echo -n -e  $res ;
		done; 
	echo "";
done > $temporaryfile

sed 's/\t$//' $temporaryfile
