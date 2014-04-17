suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("ggplot2"))
suppressPackageStartupMessages(library("reshape"))

option_list <- list(make_option(c("-e", "--gff"), help="gff exon table (gff)"),
		    make_option(c("-i", "--tsv"), help="exon table (tsv)"),
                    make_option(c("-o", "--pdf"), help="pdf output"))

opt <- parse_args(OptionParser(option_list=option_list))

data  = read.delim(opt$tsv)

p_in <- pipe(paste("print_gff_attributes.pl INT  pos <", opt$gff), 'r')
exons = read.delim(p_in, header=F)

entropy <- function(x) {y=sum(x);x[x==0]<- 1;log2(y)-sum(x*log2(x))/y}

func1 <- function(data, main) {
  unlist(lapply(strsplit(rownames(data), "_"), function(x){as.numeric(x[3]) - as.numeric(x[2]) + 1})) -> l

  hist(l[l<=100], xlab="main length (nt)", main=main, breaks=seq(-0.5,100.5,1))

  apply(data, 1, function(x){length(x[x!=0])}) -> x
  hist(x, xlab="number of samples", main=main)

  apply(data, 1, entropy) -> y
  hist(y, breaks=100, xlab="entropy (bit)", main=main)
}

func2 <- function(data,main="") {
    df = data.frame(s = apply(data,1,sum), Annotated = rownames(data) %in% exons$V1)
    res=c()
    #for(q in quantile(df$s, prob=seq(0.1,0.9,0.1))) {
    for(q in c(1,2,5,10)) {
    	A = count(subset(df,s>=q),'Annotated')
    	A$s = round(q,digits=0)
    	res=rbind(res,A)
    }
    print(ggplot(res,aes(x=factor(s), y=freq, fill=Annotated)) + geom_bar(stat = "identity", position = "stack") + xlab("# supporting reads") +ggtitle(main))
    print(res)
}


pdf(opt$pdf)
func1(data,'Mini- and micro-exons')
func2(data,'Mini- and micro-exons')
unlist(lapply(strsplit(rownames(data), "_"), function(x){as.numeric(x[3]) - as.numeric(x[2]) + 1})) -> l
func2(data[l<10,],'Micro-exons')

data1 = data[!rownames(data) %in% exons$V1,]
func1(data1, 'Novel mini- and micro-exons')


exons1 = subset(exons, V1 %in% rownames(data))
hist(exons1$V2, main="position of exon within the gene", xlab="% (0=5'-UTR, 1=3'-UTR)")

dev.off()


