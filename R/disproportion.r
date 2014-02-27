suppressPackageStartupMessages(library("optparse"))
option_list <- list(make_option(c("-b", "--bed"),  help="bed input"),
                    make_option(c("-p", "--pdf"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))

print(opt$bed)
data = read.delim(opt$bed, header=F)[,-(4:5)] # read bed

merge(subset(data,V6=='+'),subset(data,V6=='-'), by=1:3, all=T) -> A
f = paste("p =",round(dim(na.omit(A))[1]/dim(A)[1], digits=2))

print(opt$pdf)
pdf(opt$pdf)
if(nrow(A)>0) {
    with(na.omit(A), hist(log10(V7.x) - log10(V7.y), breaks=50, xlab="log(count+)-log(count-)", main=opt$pdf, sub=f))
}
dev.off()

