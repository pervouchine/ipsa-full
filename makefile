DIR=data/
MAPTOOLSDIR=maptools-2.0/
SJCOUNTDIR=sjcount-2.0/

###############################################################################################

all :: ${SJCOUNTDIR}sjcount ${MAPTOOLSDIR}bin/transf ${MAPTOOLSDIR}bin/getsegm

${SJCOUNTDIR}sjcount : 
	wget https://github.com/pervouchine/sjcount/archive/v2.0.tar.gz -O v2.0.tar.gz
	tar -xf v2.0.tar.gz 
	rm -f v2.0.tar.gz
	make -C ${SJCOUNTDIR} all

${MAPTOOLSDIR}bin/transf ${MAPTOOLSDIR}bin/getsegm:
	wget https://github.com/pervouchine/maptools/archive/v2.0.tar.gz -O v2.0.tar.gz
	tar -xf v2.0.tar.gz 
	rm -f v2.0.tar.gz
	mkdir -p ${MAPTOOLSDIR}bin/
	make -C ${MAPTOOLSDIR} all

clean ::
	rm -f -r ${SJCOUNTDIR} ${MAPTOOLSDIR}

###############################################################################################

run ::	example.mk
	make -f example.mk all  
clean ::
	rm -f -r example.dat example.mk

###############################################################################################

${DIR}gencode.v18.annotation.gtf :
	mkdir -p ${DIR}
	wget ftp://ftp.sanger.ac.uk/pub/gencode/release_18/gencode.v18.annotation.gtf.gz -O ${DIR}gencode.v18.annotation.gtf.gz
	gunzip -f ${DIR}gencode.v18.annotation.gtf.gz

${DIR}chr1.fa :
	mkdir -p ${DIR}
	wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/chromFa.tar.gz -O ${DIR}chromFa.tar.gz
	tar -xf ${DIR}chromFa.tar.gz -C ${DIR}
	rm -f ${DIR}chromFa.tar.gz 

${DIR}hg19.idx ${DIR}hg19.dbx : ${DIR}chr1.fa
	mkdir -p ${DIR}
	${MAPTOOLSDIR}bin/transf -dir ${DIR}chr1.fa -idx ${DIR}hg19.idx -dbx ${DIR}hg19.dbx

${DIR}hg19v18.gff : ${DIR}gencode.v18.annotation.gtf
	perl Perl/transcript_elements.pl -gtf ${DIR}gencode.v18.annotation.gtf > ${DIR}hg19v18.gff

example.dat : 
	wget http://genome.crg.eu/~dmitri/export/ipsa/example_ipsa.dat -O example.dat

example.mk : ${DIR}hg19.idx ${DIR}hg19.dbx ${DIR}hg19v18.gff example.dat makefile
	perl Perl/make.pl -repository input/ -dir output/ -group idrGroup -param '-read1 0' -annot ${DIR}hg19v18.gff -genome ${DIR}hg19 -merge pooled < example.dat > example.mk

