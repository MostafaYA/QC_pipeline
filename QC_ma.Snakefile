
"""
quick assessment of MiSeq reads (fastqc, species identification, coverage and estimated genome size)
Friedrich-Loefller-Institut 2019.01.28
Authors: Mostafa Abdel-Glil and Jörg Linde
"""
runfolder="190315_M05407_0022_000000000-C7JLG"
#AGfolder="AGr110"
##homfolder="mostafa.abdel/trails_JUNK"
#raw_data_dir = "/data/"+AGfolder+"/RawData/Illumina/"+runfolder+"/"
#results = "/home/Share/QC_sequencing_runs/"+runfolder+"/"
raw_data_dir = "/data/AGr150/RawData/Illumina/190315_M05407_0022_000000000-C7JLG"
results = "/home/mostafa.abdel/pipelines/QC-Pipeline/QC_sequencing_runs/"+runfolder+"/"
multiqc_dir = results + "/multiqc/"

SAMPLES, = glob_wildcards( raw_data_dir + "{sample}_L001_R1_001.fastq.gz") #data: 11T0323_S9_L001_R1_001.fastq.gz
minikraken_db_dir = "/home/mostafa.abdel/dbs/miniKraken/minikraken_20171019_8GB" #/home/DB_RAM/KrakenDB
fastqc_dir = results + "fastqc_dir/"
kraken_fastq_dir = results + "kraken_fastq_dir/"
coverage_res = results + "coverage_res/"
envs_folder = "/data/AGr110/RawData/Illumina/QC_pipeline/envs/"
log_folder = results + "log_folder/"
scripts_dir = "/data/AGr110/RawData/Illumina/QC_pipeline/scripts"#kraken_report_mqc.sh

rule all:
    input:
        FastQC=expand(fastqc_dir + "{sample}/{sample}_L001_R2_001_fastqc.zip", sample=SAMPLES),
        Kraken_fastq=expand(kraken_fastq_dir + "{sample}.report.txt", sample=SAMPLES),
        KrakenSummary= kraken_fastq_dir + "kraken_reads_per_species_mqc.txt",
        #coverage=expand(coverage_res+"{sample}.csv", sample=SAMPLES),
        multiqc_report= multiqc_dir + "multiqc_report.html"
        #CoverageInfo=expand( coverage_info_dir + "{sample}.AverageCoverage.txt", sample=SAMPLES),
        #Coverage= coverage_info_dir + "average_coverage_mqc.txt",
        #fastqc_report= multiqc_dir + "fastqc_report.html",

"""
Quality check of raw reads using FastQC
"""
rule FastQC:
    input:
        r1 = raw_data_dir + "{sample}_L001_R1_001.fastq.gz",
        r2 = raw_data_dir + "{sample}_L001_R2_001.fastq.gz"
    output:
        fastqc_zip = fastqc_dir + "{sample}/{sample}_L001_R2_001_fastqc.zip"
    threads: 32
    conda:
        envs_folder + "fastqc.yaml"
    log:
        log_folder + "{sample}/fastqc.log"
    params:
        fastqc_dir_tmp = temp(directory( fastqc_dir + "{sample}")),
    shell:
        "fastqc -t {threads} -f fastq -o {params.fastqc_dir_tmp} {input.r1} {input.r2} 2>&1 | sed 's/^/[fastqc] /' | tee -a {log}"
"""
Kraken taxonomic assignment of raw reads, screening with mini-kraken DB
"""
rule kraken: #screen the fastq files against minikraken database and summarize the results
    input:
        r1 = raw_data_dir + "{sample}_L001_R1_001.fastq.gz",
        r2 = raw_data_dir + "{sample}_L001_R2_001.fastq.gz",
    output:
        mini_kraken_seq= temp(kraken_fastq_dir + "{sample}.sequences.kraken"),
        mini_kraken_seq_label= temp(kraken_fastq_dir + "{sample}.sequences.labels"),
        mini_kraken_report= kraken_fastq_dir + "{sample}.report.txt",
    threads: 32
    log:
        log_folder + "{sample}/kraken.log"
    conda:
      envs_folder + "kraken.yaml"
    shell:
        "kraken --db {minikraken_db_dir} --paired --check-names --threads {threads} --gzip-compressed --fastq-input {input.r1} {input.r2} --output {output.mini_kraken_seq} 2>&1 | sed 's/^/[kraken] /' | tee -a {log}"
        " && kraken-translate --db {minikraken_db_dir} {output.mini_kraken_seq} > {output.mini_kraken_seq_label}"
        " && kraken-report --db {minikraken_db_dir} {output.mini_kraken_seq} > {output.mini_kraken_report}"
"""
create kraken  report for reads
"""
rule kraken_summary_reads:
    input:
        kraken_report= kraken_fastq_dir + "{sample}.report.txt",
    output:
        kraken_report_summary = temp (kraken_fastq_dir + "{sample}.kraken_results_summary.txt") #tmp file with tailing empty TAB, will be shortende by cut
    shell:
        "bash {scripts_dir}/kraken_report_summary.sh {input.kraken_report} | tee -a {output.kraken_report_summary}"

"""
create kraken mqc report for reads
"""
rule kraken_mqc_reads:
    input:
        kraken_report_summaries=expand(kraken_fastq_dir + "{sample}.kraken_results_summary.txt", sample=SAMPLES),
    output:
        kraken_mqc = kraken_fastq_dir + "kraken_reads_per_species_mqc.txt",#final result as input for MQC
    shell:
        "bash {scripts_dir}/kraken_report_mqc.sh {kraken_fastq_dir} {output.kraken_mqc} && cat {output.kraken_mqc}"

"""
#do we need to unzip the data for that???
Calculate coverage for each sample
"""
rule coverage:
    input:#input is unzipped fastq-files AND reference genome assembly
      fw=raw_data_dir + "{sample}_L001_R1_001.fastq.gz",
      rv=raw_data_dir + "{sample}_L001_R2_001.fastq.gz",
      #ref=config["refstrain"]
    output:
      out=coverage_res+"{sample}.csv"#coverage of each sample
    shell:#adapted from https://github.com/raymondkiu/fastq-info/blob/master/fastq_info_3.sh
       "sh {scripts_dir}/fastq_info_ma.sh  {input.fw} {input.rv} > {output.out}"

"""
Collects coverage result from ech sample and combines in one file
"""
rule collect_coverage:
    input:#coverage from each sample
        localres=expand(coverage_res+"{sample}.csv", sample=SAMPLES),
    output:#results in csv and xls
        allcsv=coverage_res+"allcoverage.csv",
        allxls=coverage_res+"allcoverage.xlsx",
        multiqc=coverage_res+"Coverage_fastq_info_barplot_mqc.txt",
        multiqc_table=coverage_res+"Coverage_fastq_info_table_mqc.txt",
    log:
       coverage_res+"allcoverage.log"
    #conda:
    #    envs_folder + "rxls.yaml"
    script:
        "scripts/combineCoverage.R"#converts to xls

"""
MultiQC for FastQC
"""
rule multiqc_fastqc:
    input:
        FastQC=expand(fastqc_dir + "{sample}/{sample}_L001_R2_001_fastqc.zip", sample=SAMPLES),
        KrakenSummary= kraken_fastq_dir + "kraken_reads_per_species_mqc.txt",
        multiqc_cov=coverage_res+"Coverage_fastq_info_barplot_mqc.txt",
        multiqc_table=coverage_res+"Coverage_fastq_info_table_mqc.txt",
    output:
        multiqc_report= multiqc_dir + "multiqc_report.html",
    #log:
        #log_folder + "multiqc_fastqc.log"
    #conda:
        #envs_folder + "multiqc.yaml"
    shell:
        "multiqc --filename multiqc_report --force --outdir {multiqc_dir} {fastqc_dir} {input.KrakenSummary} {input.multiqc_cov} {input.multiqc_table}"
        #"multiqc --filename fastqc_assembly_report --outdir {output.results} {input.fastqc}"
