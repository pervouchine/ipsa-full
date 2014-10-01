library(plyr)
cmd_args = commandArgs()[-(1:5)]
file_list = cmd_args[1:(length(cmd_args)-1)]

for(i in 1:(length(file_list))) {
    print(paste('Replicate', i, file_list[i]))
    data = read.delim(file_list[i], header=F)
    if(i==1) {
	res = data
    }
    else {
	merge(res, data, by=intersect(c(1,2,3,4,8,9),1:ncol(res)), all=T) -> A
	B = A[,7:ncol(A)]
    	B[is.na(B)]<-0
    	A[,7:ncol(A)] = B
	A$V5 = A$V5.x + A$V5.y
        A$V6 = A$V6.x + A$V6.y
     	A$V7 = A$V7.x + A$V7.y
	res = A[,paste('V',1:ncol(res),sep='')]
    }
}

res[,5:7] = round(res[,5:7]/length(file_list), digits=2)
res$V10=0

print(paste('Saving to', cmd_args[length(cmd_args)]))
write.table(res, file=cmd_args[length(cmd_args)], col.names=F, row.names=F, quote=F, sep="\t")
