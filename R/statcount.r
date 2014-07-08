suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(ggplot2))
option_list <- list(make_option(c("-i", "--tsv"),  help="tsv input"),
                    make_option(c("-o", "--pdf"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))

print(opt$tsv)
data = read.delim(opt$tsv, header=F)
colnames(data) = c('ann','log2count','nsp','nsj')
data$ann = factor(data$ann, levels=c(0,1,2,3), labels=c('Both unknown','One known','Two known','Intron known'))

pdf(opt$pdf, width=8, height=2)
the_base_size = 10
theme_set(theme_bw(base_size = the_base_size))
ggplot(data, aes(x=log2count,y=nsp, fill=nsj)) + geom_tile() + facet_grid(.~ann) + xlab(expression(log[2](count))) + ylab("# of samples") + scale_fill_gradient("# of SJ",low='white',high='red') #,trans="log10")
dev.off()

