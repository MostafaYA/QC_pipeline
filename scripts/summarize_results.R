require(writexl)
fastp=read.table(snakemake@input[["fastp_mqc"]],sep="\t",as.is=T,header=T,comment.char = "#")
#fastp=read.table("Results/190417_M05407_0025_000000000-C7JLY/fastp_dir/FASTQ_quality_results_mqc.txt",sep="\t",as.is=T,header=T,comment.char = "#")
kraken=read.table(snakemake@input[["KrakenSummary"]],sep="\t",as.is=T,header=T,comment.char = "#",dec=".")
#kraken=read.table("Results/190417_M05407_0025_000000000-C7JLY/kraken_fastq_dir/kraken_reads_per_species_mqc.txt",sep="\t",as.is=T,header=T,comment.char = "#",dec="."))
coverage=read.table(snakemake@input[["coverage"]],sep="\t",as.is=T,header=T,comment.char = "~",dec=".")
#coverage=read.table("Results/190417_M05407_0025_000000000-C7JLY/coverage_res/allcoverage.csv",sep="\t",as.is=T,header=T,comment.char = "~",dec=".")

colnames(kraken)= gsub("X\\.", "%", colnames(kraken))
colnames(kraken)= gsub("X", "", colnames(kraken))

cat("read input\n",file=snakemake@log[[1]],sep="")
tmp=unlist(strsplit(fastp[,"Q30.bases"],split=" "))
fastp=fastp[,c("Isolate","Total.reads","Total.bases")]
number30=tmp[seq(1,2*nrow(fastp),by=2)]
percq30=tmp[seq(2,2*nrow(fastp),by=2)]
percq30=substr(percq30,2,(nchar(percq30[[1]])-2))
fastp=cbind(fastp,number30)
fastp=cbind(fastp,percq30)
colnames(fastp)=c("Isolate","Total.reads","Total.bases","Number.Q30","Percentage.Q30")
fastp=fastp[,c("Isolate","Total.bases","Number.Q30","Percentage.Q30")]

coverage=coverage[,c("ID","Total.sequences", "Estimated.genome.size","Estimated.coverage")]
fastp_cov=merge(fastp,coverage,by.x=1,by.y=1)
all=merge(fastp_cov,kraken,by.x=1,by.y=1)
cat("merged input\n",file=snakemake@log[[1]],sep="",append=T)
all[is.na(all)] <- "NA"#replaces NA values with string NA
write_xlsx(all,snakemake@output[["allxls"]])
