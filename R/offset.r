suppressPackageStartupMessages(library("optparse"))
option_list <- list(make_option(c("-t", "--tsv"),  help="tsv input"),
                    make_option(c("-p", "--pdf"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))

print(opt$tsv)
data = read.delim(opt$tsv, header=F)
print("Aggregating")
with(subset(data, V2<2),aggregate(V4, by=list(V3), FUN=sum)) -> A
colnames(A) = c('offset','count')

pdf(opt$pdf)
with(A, barplot(count,names.arg=offset,main=opt$tsv))
dev.off()

