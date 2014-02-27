suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("plyr"))
option_list <- list(make_option(c("-b", "--bed"),  help="bed input"),
                    make_option(c("-p", "--pdf"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))


print(opt$bed)
data = read.delim(opt$bed, header=F)

stat <- function(data, message) {
    count(data, 'V11') -> A
    colnames(A) = c('Splice sites','freq')
    print(message)
    print(head(A[order(-A$freq),],10))
}

print("Annotation status")
print(count(data, 'V10'))

stat(data, "All")
stat(subset(data, V10>=2), 'Annotated')
stat(subset(data, V10<=1), 'Novel')





