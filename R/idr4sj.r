# This is a translation of Alex Dobin's npIDR script (see funIDRnpFile.m) from matlab to R
# Done on Jun 7, 2013 by Dmitri Pervouchine (dp@crg.eu)
#
# This is a version adopted for splice junction counts
# To run this script from commandline you call 

npIDR <- function(data) {
    # input:  data matrix n-by-2
    # output: column of npIDR
    colnames(data) = c('V1','V2')

    merge(count(data,'V1'),count(data,'V2'),by=1,all=T) -> absolute
    absolute[is.na(absolute)] <- 0
    absolute$sum = absolute$freq.x + absolute$freq.y

    merge(count(subset(data,V2==0),'V1'), count(subset(data,V1==0),'V2'), by=1,all=T) -> conditional
    conditional[is.na(conditional)] <- 0
    conditional$sum = conditional$freq.x + conditional$freq.y

    subset(merge(absolute, conditional, by=1, all=T), V1>0) -> matr
    matr[is.na(matr)] <- 0
    npIDR=matr$sum.y/matr$sum.x
    names(npIDR) = matr$V1

    sPool = apply(data, 1, sum)
    output = npIDR[as.character(sPool)]
    output[is.na(output)]<-0
    round(output, digits=4)
}


library(plyr)
cmd_args = commandArgs()[-(1:5)]
idr_default = 0

data = list()
for(i in 1:(length(cmd_args)-1)) {
    print(paste('Replicate', cmd_args[i]))
    data[[i]] = read.delim(cmd_args[i], header=F) # read replicate 1
}

if(length(cmd_args)==2) {
    A = data[[1]]
    A$idr = idr_default
}

if(length(cmd_args)>2) {
    merge(data[[1]], data[[2]], by=intersect(c(1,2,3,4,8,9),1:ncol(data[[1]])), all=T) -> A    # merge and replace NAs by 0
    B = A[,7:ncol(A)]
    B[is.na(B)]<-0
    A[,7:ncol(A)] = B
    npIDR(A[,c('V5.x','V5.y')]) -> A$idr
    A$V5 = A$V5.x + A$V5.y
    A$V6 = A$V6.x + A$V6.y
    A$V7 = A$V7.x + A$V7.y
}

print(paste('Saving to', cmd_args[length(cmd_args)]))
write.table(A[,c(colnames(data[[1]]), 'idr')], file=cmd_args[length(cmd_args)], col.names=F, row.names=F, quote=F, sep="\t")
