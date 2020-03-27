
"""
quick assessment of MiSeq qreads (fastqc, species identification, coverage and estimated genome size)
Friedrich-Loefller-Institut 2019.01.28
Authors: Mostafa Abdel-Glil and Jörg Linde

"""
configfile: "config.yaml"
snakemake_folder=config['snakemake_folder']
raw_data_dir=config['raw_data_dir']
results=config['results_dir']
kraken_db_dir=config['kraken']

"""optional arguments"""
if "kraken2_opts" in config:
    kraken2_opts= config["kraken2_opts"]
else:
    kraken2_opts= ""

"""SAMPLES"""
#SAMPLES, INDEXES = glob_wildcards( raw_data_dir + "{sample}_S{index}_L001_R1_001.fastq.gz") #data: 11T0323_S9_L001_R1_001.fastq.gz
#SAMPLES, = glob_wildcards( raw_data_dir + "{sample}_L001_R1_001.fastq.gz")
SAMPLES, = glob_wildcards( raw_data_dir + "{sample}_R1.fastq.gz")

"""directories"""
envs_folder = snakemake_folder + "envs/"
scripts_dir = snakemake_folder + "scripts"#kraken_report_mqc.sh
fastqc_dir = results + "fastqc_dir/"
kraken_fastq_dir = results + "kraken_fastq_dir/"
fastp_dir= results + "fastp_dir/"
coverage_res = results + "coverage_res/"
log_folder = results + "log_folder/"
multiqc_dir = results + "multiqc/"

"""variables"""
#r1 = raw_data_dir + "{sample}_L001_R1_001.fastq.gz",
#r2 = raw_data_dir + "{sample}_L001_R2_001.fastq.gz"
#fastqc_zip_trail = "_L001_R2_001_fastqc.zip"
r1 = raw_data_dir + "{sample}_R1.fastq.gz",
r2 = raw_data_dir + "{sample}_R2.fastq.gz"
fastqc_zip_trail = "_R2_fastqc.zip"


rule all:
    input:
        FastQC=expand(fastqc_dir + "{sample}/{sample}" + fastqc_zip_trail, sample=SAMPLES),
        Kraken_fastq=expand(kraken_fastq_dir + "{sample}.report.txt", sample=SAMPLES),
        KrakenSummary= kraken_fastq_dir + "kraken2_reads_per_species_mqc.txt",
        fastp_tsv= fastp_dir + "FASTQ_quality_results.txt",
        multiqc_report= multiqc_dir + "multiqc_report.html",
        allxls=results+"QCSummary.xlsx"

"""
FastQC
"""
rule FastQC:
    input:
        r1 = r1, r2 = r2
    output:
        fastqc_zip = fastqc_dir + "{sample}/{sample}" + fastqc_zip_trail
    threads: 16
    conda:
        envs_folder + "fastqc.yaml"
    log:
        log_folder + "{sample}/fastqc.log"
    params:
        fastqc_dir_tmp = temp(directory( fastqc_dir + "{sample}")),
    shell:
        "fastqc -t {threads} -f fastq -o {params.fastqc_dir_tmp} {input.r1} {input.r2} 2>&1 | sed 's/^/[fastqc] /' | tee -a {log}"
"""
Kraken
"""
rule kraken: #screen the fastq files against kraken database and summarize the results
    input:
        r1 = r1, r2 = r2,
    output:
        kraken_report= kraken_fastq_dir + "{sample}.report.txt",
    threads: 16
    log:
        log_folder + "{sample}/kraken.log"
    conda:
      envs_folder + "kraken.yaml"
    shell:
        "kraken2 --db {kraken_db_dir} --paired --threads {threads} --gzip-compressed {input.r1} {input.r2}  --output -  --report {output.kraken_report} {kraken2_opts} 2>&1 | sed 's/^/[kraken2] /' | tee -a {log}" #-



"""
create kraken species reads mqc report
"""
rule kraken_mqc_reads_sepcies:
    input:
        localres=expand(kraken_fastq_dir+"{sample}.report.txt", sample=SAMPLES),#expand(kraken_fastq_dir + "{sample}.report.txt",sample=SAMPLES),
    output:
        kraken_mqc = kraken_fastq_dir + "kraken2_reads_per_species_mqc.txt",#final result as input for MQC
    log:
        log_folder+"kraken_mqc_sepcies.log"
    params:
        cut="S"
    conda:
        envs_folder + "rxls.yaml"
    script:
        scripts_dir+"/kraken_report_mqc.R"



"""
kraken report summary

rule kraken_summary_reads:#
    input:
        kraken_report= kraken_fastq_dir + "{sample}.report.txt",
    output:
        kraken_report_summary = temp (kraken_fastq_dir + "{sample}.kraken_results_summary.txt")
    shell:
        "bash {scripts_dir}/kraken_report_summary.sh {input.kraken_report} | tee -a {output.kraken_report_summary} 2>&1 | sed 's/^/[kraken2-Results] /' "

"""
"""
kraken mqc report

rule kraken_mqc_reads:
    input:
        kraken_report_summaries=expand(kraken_fastq_dir + "{sample}.kraken_results_summary.txt", sample=SAMPLES),
    output:
        kraken_mqc = kraken_fastq_dir + "kraken2_reads_per_species_mqc.txt",#final result as input for MQC
    shell:
        "bash {scripts_dir}/kraken_report_mqc.sh {kraken_fastq_dir} {output.kraken_mqc} && cat {output.kraken_mqc} 2>&1 | sed 's/^/[kraken2-Results] /'"

"""
"""
Calculate coverage
"""
rule coverage:
    input:
      r1= r1, r2= r2,
    output:
      out=coverage_res+"{sample}.csv"#coverage of each sample
    conda:
      envs_folder + "coverage.yaml"
    shell:
       "sh {scripts_dir}/fastq_info_ma.sh  {input.r1} {input.r2} > {output.out}"
"""
fastp
"""
rule fastp:
    input:
        r1 = r1, r2 = r2,
    output:
        fastp_html = fastp_dir + "{sample}.fastp.html",
        fastp_json = temp(fastp_dir + "{sample}.fastp.json"),
        pandoc_md = temp(fastp_dir + "{sample}.pandoc.md"),
        before_filtr_stats= temp(fastp_dir + "{sample}.stats.txt"),
        final_stats= fastp_dir + "{sample}.fastp_results_summary.txt",
    threads: 16
    log:
        log_folder + "{sample}/fastp.log"
    conda:
      envs_folder + "fastp.yaml" #fastp, pandoc
    params:
      report_title="{sample}",
    shell:
        "fastp -i {input.r1}  -I {input.r2} --disable_quality_filtering --disable_adapter_trimming --disable_length_filtering --disable_trim_poly_g --json {output.fastp_json} --html {output.fastp_html} --thread {threads} --verbose --report_title {params.report_title} 2>&1 | sed 's/^/[fastp] /' | tee -a {log}"
        " && pandoc -s -r html {output.fastp_html} -o {output.pandoc_md}"
        " && grep -m 1 -A 7 'Before filtering' {output.pandoc_md} | tail -n5 > {output.before_filtr_stats}"
        " && sh {scripts_dir}/fastp_stats.sh {output.before_filtr_stats} > {output.final_stats}"
"""
collect fastp
"""
rule collect_fastp:
    input:
        final_stats= expand(fastp_dir + "{sample}.fastp_results_summary.txt", sample=SAMPLES),
    output:
        fastp_tsv= fastp_dir + "FASTQ_quality_results.txt",
        fastp_mqc= fastp_dir + "FASTQ_quality_results_mqc.txt"
    shell:
        "bash {scripts_dir}/fastp_stats_mqc.sh {fastp_dir} {output.fastp_mqc} {output.fastp_tsv} && cat {output.fastp_mqc} 2>&1 | sed 's/^/[fastp-Results] /'"

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
       log_folder+"allcoverage.log"
    conda:
        envs_folder + "rxls.yaml"
    script:
        scripts_dir+"/combineCoverage.R"#converts to xls

"""
Summarizes results from:Q30(fastp), coverage, kraken
"""
rule summarize_results:
    input:#coverage from each sample
        KrakenSummary= kraken_fastq_dir + "kraken2_reads_per_species_mqc.txt",
        coverage=coverage_res+"allcoverage.csv",
        fastp_mqc= fastp_dir + "FASTQ_quality_results_mqc.txt"
    output:#results in csv and xls
        allxls=results+"QCSummary.xlsx",
    log:
       log_folder+"summarize_results.log"
    conda:
        envs_folder + "rxls.yaml"
    script:
        scripts_dir+"/summarize_results.R"#converts to xls
"""
MultiQC for FastQC
"""
rule multiqc_fastqc:
    input:
        FastQC=expand(fastqc_dir + "{sample}/{sample}" + fastqc_zip_trail, sample=SAMPLES),
        KrakenSummary= kraken_fastq_dir + "kraken2_reads_per_species_mqc.txt",
        multiqc_cov=coverage_res+"Coverage_fastq_info_barplot_mqc.txt",
        multiqc_table=coverage_res+"Coverage_fastq_info_table_mqc.txt",
        fastp_mqc= fastp_dir + "FASTQ_quality_results_mqc.txt"
    output:
        multiqc_report= multiqc_dir + "multiqc_report.html",
    log:
        log_folder + "multiqc_fastqc.log"
    conda:
        envs_folder + "multiqc.yaml"
    shell:
        "multiqc --filename multiqc_report --force --outdir {multiqc_dir} {fastqc_dir} {input.KrakenSummary} {input.multiqc_cov} {input.multiqc_table} {input.fastp_mqc} | tee -a {log}"
        #"multiqc --filename fastqc_assembly_report --outdir {output.results} {input.fastqc}"
