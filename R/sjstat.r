suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("plyr"))
option_list <- list(make_option(c("-i", "--inp"), help="tsv input"))

opt <- parse_args(OptionParser(option_list=option_list))

print(opt$inp)
data = read.delim(opt$inp, header=F)

stat <- function(data, message) {
    count(data, 'V9') -> A
    colnames(A) = c('Splice sites','freq')
    print(message)
    print(head(A[order(-A$freq),],10))
}

print("Annotation status")
print(count(data, 'V8'))
stat(data, "All")
stat(subset(data, V8>=2), 'Annotated')
stat(subset(data, V8<=1), 'Novel')





