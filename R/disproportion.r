suppressPackageStartupMessages(library("optparse"))
option_list <- list(make_option(c("-i", "--inp"), help="tsv input"),
                    make_option(c("-o", "--out"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))

print(opt$inp)
data = read.delim(opt$inp, header=F)

merge(subset(data,V4=='+'),subset(data,V4=='-'), by=1:3, all=T) -> A
f = paste("p =",round(dim(na.omit(A))[1]/dim(A)[1], digits=2))

print(opt$out)
pdf(opt$out)
if(nrow(A)>0) {
    with(na.omit(A), hist(log10(V5.x) - log10(V5.y), breaks=50, xlab="log(count+)-log(count-)", main=opt$pdf, sub=f))
}
dev.off()

