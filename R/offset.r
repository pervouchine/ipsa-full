suppressPackageStartupMessages(library("optparse"))
option_list <- list(make_option(c("-t", "--tsv"),  help="tsv input"),
                    make_option(c("-p", "--pdf"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))

print(opt$tsv)
data = read.delim(opt$tsv, header=F)
print("Aggregating")
aggregate(data$V6, by=list(data$V5), FUN=sum) -> A
colnames(A) = c('offset','count')

pdf(opt$pdf)
with(A, barplot(count,names.arg=offset,main=opt$tsv))
dev.off()

