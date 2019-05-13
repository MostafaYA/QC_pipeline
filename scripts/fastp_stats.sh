#!/bin/bash
#date: January, 11, 2019, Friedrich-Loeffler-Institut (https://www.fli.de/)


inputfile=$1

for f in $inputfile; do
#remove path take only filename
	j=$(basename $f);
#remove ".txt" output sample name
	echo -ne ${j%.stats.txt}'\t';
		reads=$(grep "total reads" $f |sed 's/total reads://;s/M//;s/ //g;s/\./,/');
		bases=$(grep "total bases" $f |sed 's/total bases://;s/M//;s/ //g;s/\./,/');
		Q20=$(grep "Q20" $f |sed 's/Q20 bases://;s/ //g;s/M//;s/(/ (/;s/\./,/');
		Q30=$(grep "Q30" $f |sed 's/Q30 bases://;s/ //g;s/M//;s/(/ (/;s/\./,/');
		GC=$(grep "GC content" $f |sed 's/GC content://;s/ //g');
#echo -n -e "$reads\t";
#echo -n -e "$bases\t";
#echo -n -e "$Q20\t";
#echo -n -e "$Q30\t";
#echo -e "$GC\t";
#output
			res=$reads'\t'$bases'\t'$Q20'\t'$Q30'\t'$GC'\n';
			#echo -n -e   "${res::-1}";
				echo -n -e  $res ;
done
