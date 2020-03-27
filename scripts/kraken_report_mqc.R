fileList <- snakemake@input[["localres"]]
#fileList=list.files("results/kraken/contigs/", recursive=T,full.names=T,pattern=".report.txt")
#cat(fileList[[1]],file= "/home/pipelines/qc_pipeline/fileList.csv")



cat("read file list\n",file=snakemake@log[[1]],sep="")
cat(snakemake@input[["localres"]],file=snakemake@log[[1]],sep="",append=T)
cat("\n",file=snakemake@log[[1]],sep="",append=T)

cat(snakemake@params[["cut"]],file=snakemake@log[[1]],sep="",append=T)

report_kraken=function(file,type="S",max=4){

  krakenreport=read.delim(file,as.is=T)
#  ID=unlist(strsplit(file,"/"))[5]
  #tmp=unlist(strsplit(file,"/"))
  #ID=tmp[length(tmp)-1]

  ID = basename(file)


  krakenreport=krakenreport[krakenreport[,4]=="U"|krakenreport[,4]==type,]
  krakenreport=krakenreport[order(krakenreport[,1],decreasing=T),c(6,1)]
  if(nrow(krakenreport)<max) {
    new=max-nrow(krakenreport)
    for(i in 1:new) krakenreport=rbind(krakenreport,c(NA,NA))
  }
  krakenreport=krakenreport[1:max,]
  krakenreport[,1]=trimws(krakenreport[,1])
  return(c(ID,as.vector(t(krakenreport))))

}

dataList<- lapply(fileList,report_kraken,type=snakemake@params[["cut"]])#read all results
cat("read data\n",file=snakemake@log[[1]],sep="",append=T)

res<- do.call("rbind",dataList)#combine columns
#write.table(res, "/home/pipelines/qc_pipeline/res.csv", quote=FALSE, sep="\t", row.names=FALSE, col.names=TRUE, append=TRUE, qmethod = c("escape"))

cat("combined data\n",file=snakemake@log[[1]],sep="",append=T)

colnames(res)=c("ID","1stMatch","%1stMatch","2ndMatch","%2ndMatch","3rdMatch","%3rdMatch","4thMatch","%4thMatch")
res[,1]=gsub(".txt","",res[,1])
res[,1]=gsub(".report","",res[,1])


cat("finnished\n",file=snakemake@log[[1]],sep="",append=T)

title <- "# title: 'Number and percentage of reads from first four highest hits by kraken2'"
section <- "# section: ''"
desc <- "# description: ''"
format <- "# format: 'tsv'"
plot_type <- "# plot_type: 'table'"
#config<-"# pconfig:"
#id<-"#    id: 'Coverage from fastq_info'"
#ylab<-"#    ylab: 'Coverage'"


writeLines(c(title, desc, section, format, plot_type),snakemake@output[["kraken_mqc"]] )
write.table(res, file=snakemake@output[["kraken_mqc"]], quote=FALSE, sep="\t", row.names=FALSE, col.names=TRUE, append=TRUE, qmethod = c("escape"))
cat("successfully created input for MultiQC \n",file=snakemake@log[[1]],sep="",append=T)
