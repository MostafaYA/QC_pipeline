#!/bin/bash -e
#Friedrich-Loeffler-Institut (https://www.fli.de/), IBIZ
#date: Mai, 2, 2019
#Author: Mostafa Abdel-Glil (mostafa.abdel-glil@fli.de)
# A bash script to generate input folder and run the snakefile
#TODO
#directly edit the config file to use with snakemake
#check dependencies

pushd . > /dev/null
DIR="${BASH_SOURCE[0]}"
while [ -h "$DIR" ]; do cd "$(dirname "$DIR")"; DIR="$(readlink "$(basename "$DIR")")"; done
cd "$(dirname "$DIR")"
DIR="$(pwd)/"
popd > /dev/null #SOURCE
#make a help MSG and pass arguments
PROGNAME=`basename $0`
function usage { echo "USAGE:
   bash ./checkQC.sh -d fastq_directory -o Output_directory
REQUIRED:
   -d, --fastq-directory  DIR, a directory where the fastq reads are present
OPTIONAL:
   -l, --linksdir         DIR, a directory to create links for the reads (default: linksdir/)
   -o, --outdir           DIR, an output directory for the snakemake results (default: output/)
   --run [true, false]    Automatically run snakemake (default: true)
   -h, --help             This help" ; }
function error_exit { echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2; exit 1; } #SOURCE
function remove_trailing_slash { string="$1" ; new_string=`echo "$string" | perl -nl -e 's/\/+$//;' -e 'print $_'` ; echo $new_string ; } #SOURCE
while [ "$1" != "" ]; do
    case $1 in
        -d | --fastq-directory ) shift; fastqdirectory=$1 ;;
        -l | --linksdir ) shift; linksdir=$1 ;;
        -o | --outdir ) shift; outdir=$1 ;;
        --run ) shift; RUN=$1 ;;
        -h | --help )  usage; exit ;;
        * ) usage; exit 1
    esac
    shift
done
linksdir_default='linksdir'
outdir_default='output'
if [[ -z $fastqdirectory ]] ; then error_exit "must specify a fastq directory, use '-d' - exit" ; fi
if [[ -z $linksdir ]]; then linksdir=$linksdir_default; fi
if [[ -z $outdir ]]; then outdir=$outdir_default; fi
if [[ -z $RUN ]]; then RUN=true; fi

if [[ ! -e $linksdir ]]; then mkdir -p $linksdir;
else linksdir="$linksdir"_"$(date '+%d%b%Y_%H%M%S')" && mkdir -p $linksdir
fi
#mkdir -p $linksdir
#variables
fastqdir=`remove_trailing_slash "$fastqdirectory"`
linksdir=`remove_trailing_slash "$linksdir"`
linksdir=$( realpath $linksdir)
outdir=`remove_trailing_slash "$outdir"`
#outdir=$( realpath $outdir)
#make the output directory, add a timpestamp if the directoy already exists


#first scan the folder for the reads and create error if the reads don't match the required pattern
CheckSamples=$((ls ${fastqdir}/*.{fastq,fastq.gz,fq,fq.gz,fasta,fna,fa,fsa,fs,fnn} 2> /dev/null | xargs -n 1 basename 2> /dev/null) | awk '{print NF}' | sort | uniq )
if [[ $CheckSamples != 1 ]];
  then echo -e "\e[31mcan not guess the samples. Samples names must end with [fastq,fastq.gz,fq,fq.gz] - exit\e[39m";
  exit 1;
fi ;
#get the ID of the sample
printf "Guessing IDs.....\n"
echo "--------------------------------------------------------------------------------"
#id is the what is mentioned before the first underscore in the name
ID=$(awk 'BEGIN{FS="_"}{ print $1 }' <(ls ${fastqdir}/*.{fastq,fq} 2> /dev/null | xargs -n 1 basename 2> /dev/null; ls ${fastqdir}/*{fastq,fq}.gz 2> /dev/null | xargs -n 1 basename 2> /dev/null) | uniq | sort)
printf "The follwoing IDs are predicted for the Samples: \n${ID}\n\n"
echo "--------------------------------------------------------------------------------"
#Compress the fastqfiles if uncompressed
Checkonlyfastq=$((ls ${fastqdir}/*.{fastq,fq} 2> /dev/null | xargs -n 1 basename 2> /dev/null) | awk '{print NF}' | sort | uniq )
Checkonlyfq=$((ls ${fastqdir}/*fq 2> /dev/null | xargs -n 1 basename 2> /dev/null) | awk '{print NF}' | sort | uniq )
if [[ $Checkonlyfastq = 1 ]];
  then echo -e "found uncompressed fastq file. Creating .gz files. Original files will not be affected";
  pigz --keep ${fastqdir}/*fastq
  echo "--------------------------------------------------------------------------------"
  if [[ $Checkonlyfq = 1 ]];
    then echo -e "found uncompressed fq file. Creating .gz files. Original files will not be affected";
    pigz --keep ${fastqdir}/*fq
    echo "--------------------------------------------------------------------------------"
  fi;
fi ;
#get the full path of the reads
echo "Creating links for the fastq reads"
for ID in $(awk 'BEGIN{FS="_"}{ print $1 }' <(ls ${fastqdir}/*.{fastq,fq}.gz 2> /dev/null | xargs -n 1 basename 2> /dev/null) | uniq | sort);
  do
    FILES1=$(realpath $(ls ${fastqdir}/${ID}*_R1_*.gz  2>/dev/null ) 2>/dev/null)
    FILES2=$(realpath $(ls ${fastqdir}/${ID}*_R2_*.gz  2>/dev/null ) 2>/dev/null)
        NF1=$(echo $FILES1 | awk '{print NF}')
    if [[ $NF1 -lt 1 ]]
    then
        #if the reads dont match the format *_R1_*.gz, then check for *_1.fastq. if both formats are not there, then exit
        FILES1=$(realpath $(ls ${fastqdir}/${ID}*_1.*.gz 2>/dev/null ) 2>/dev/null)
        FILES2=$(realpath $(ls ${fastqdir}/${ID}*_2.*.gz 2>/dev/null ) 2>/dev/null)
        NF1=$(echo $FILES1 | awk '{print NF}')
        if [ $NF1 -lt 1 ]
        then
            echo -e "\e[31mfile pattern must match *ID*_R1_*.fastq or *ID*_1.fastq. Files could also be zipped .gz\e[39m"
            exit 1
        fi
    fi
echo "ln -s -f "$FILES1" "$linksdir"/"$ID"_R1.fastq.gz"
ln -s -f "$FILES1" "$linksdir"/"$ID"_R1.fastq.gz
echo "ln -s -f "$FILES2" "$linksdir"/"$ID"_R2.fastq.gz"
ln -s -f "$FILES2" "$linksdir"/"$ID"_R2.fastq.gz
done
rm -f "$linksdir"/Undetermined_R2.fastq.gz
rm -f "$linksdir"/Undetermined_R1.fastq.gz
echo "--------------------------------------------------------------------------------"
echo "$linksdir is created successfully"
echo "--------------------------------------------------------------------------------"
#update the config file
echo "writing config file"
if [[ -e config.yaml ]]; then
  config=config.yaml
  config_actual=config_"$(date '+%d%b%Y_%H%M%S')".yaml
  echo -e "Found $config. Assume that the current directory is where the QC_ma.snakefile is downloaded. Writing the $config_actual file with the paths..."
  var=`pwd`; sed -e "s|snakemake_folder: |snakemake_folder: $var/ #|g" $config > $config_actual
  sed -i "s|raw_data_dir: |raw_data_dir: $linksdir/ #|g" $config_actual
  sed -i "s|results_dir: |results_dir: $outdir/ #|g" $config_actual
else
  echo -e "\e[1m\e[38:2:240:143:104mCannot find the file: config.yaml. Please update it manually with the paths of the raw_data_dir and the fasta_dir\e[0m\e[39m"
fi

echo "--------------------------------------------------------------------------------"
echo "Please note:"
echo -e "To see what snakemake will do, run: \e[38;5;42m\e[1msnakemake --snakefile QC_ma.Snakefile --cores 128 --use-conda --configfile $config_actual -np \e[39m\e[0m"
echo -e "To execute the pipeline, run: \e[38;5;42m\e[1msnakemake --snakefile QC_ma.Snakefile --cores 128 --use-conda --configfile $config_actual -p \e[39m\e[0m"
#echo "To avoid conda problems, run: export PERL5LIB=\""\"

if [[  $RUN =  "true" ]];
then
  echo -ne "\n\n\n"
  echo "Running snakemake"
  echo -ne "\n"
  export PERL5LIB=""
  snakemake --snakefile QC_ma.Snakefile --cores 128 --use-conda -p --configfile $config_actual
  rm $linksdir/*.gz && rmdir $linksdir
fi
#snakemake --snakefile snakeNullarbor.Snakefile -np --cores 128 -p --use-conda

#Documentation
