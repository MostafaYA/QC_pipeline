require(writexl)
fileList <- snakemake@input[["localres"]]
cat("read file list\n",file=snakemake@log[[1]],sep="")



## Read all coverage files
dataList <- lapply(fileList,read.delim,as.is=T)
cat("read data\n",file=snakemake@log[[1]],sep="",append=T)

## Combine all data
covData <- do.call("rbind",dataList)
cat("combined data\n",file=snakemake@log[[1]],sep="",append=T)


tmp=strsplit(covData[,1],"_R1")#create ID vector and remove fastq names
ID=rep(NA,nrow(covData))#intiliales results
for(i in 1:length(ID)) ID[i]=tmp[[i]][1]#take first element after _
covData=cbind(ID,covData)#replace first two columns with ID and name
colnames(covData)[1]="ID"

write.table(covData,snakemake@output[["allcsv"]],row.names=F,sep="\t",quote=F)
write_xlsx(covData,snakemake@output[["allxls"]])
cat("successfully created XLS \n",file=snakemake@log[[1]],sep="",append=T)


# write mqc report (for multiQC)

title <- "# title: 'Coverage'"
section <- "# section: ''"
desc <- "# description: ''"
format <- "# format: 'tsv'"
plot_type <- "# plot_type: 'bargraph'"
#config<-"# pconfig:"
#id<-"#    id: 'Coverage from fastq_info'"
#ylab<-"#    ylab: 'Coverage'"


covonly=covData[,c(1,ncol(covData))]#take first and last columns ID, coverage
writeLines(c(title, desc, section, format, plot_type),snakemake@output[["multiqc"]] )
write.table(covonly, file=snakemake@output[["multiqc"]], quote=FALSE, sep="\t", row.names=FALSE, col.names=TRUE, append=TRUE, qmethod = c("escape"))
cat("successfully created barplot for MultiQC \n",file=snakemake@log[[1]],sep="",append=T)

title <- "# title: 'Coverage'"
section <- "# section: ''"
desc <- "# description: ''"
format <- "# format: 'tsv'"
plot_type <- "# plot_type: 'table'"
covData=covData[,c(1,4:ncol(covData))]#take first and last columns ID, coverage

writeLines(c(title, desc, section, format, plot_type),snakemake@output[["multiqc_table"]] )
write.table(covData, file=snakemake@output[["multiqc_table"]], quote=FALSE, sep="\t", row.names=FALSE, col.names=TRUE, append=TRUE, qmethod = c("escape"))
