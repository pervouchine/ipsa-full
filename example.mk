COMMON_DIR=data/

all :: ${COMMON_DIR}hg19.idx ${COMMON_DIR}hg19.dbx ${COMMON_DIR}hg19v18.gff

${COMMON_DIR}gencode.v18.annotation.gtf :
	mkdir -p ${COMMON_DIR}
	wget ftp://ftp.sanger.ac.uk/pub/gencode/release_18/gencode.v18.annotation.gtf.gz -O ${COMMON_DIR}gencode.v18.annotation.gtf.gz
	gunzip -f ${COMMON_DIR}gencode.v18.annotation.gtf.gz

${COMMON_DIR}chr1.fa :
	mkdir -p ${COMMON_DIR}
	wget http://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/chromFa.tar.gz -O ${COMMON_DIR}chromFa.tar.gz
	tar -xf ${COMMON_DIR}chromFa.tar.gz -C ${COMMON_DIR}

${COMMON_DIR}hg19.idx ${COMMON_DIR}hg19.dbx : ${COMMON_DIR}chr1.fa
	mkdir -p ${COMMON_DIR}
	maptools/bin/transf -dir ${COMMON_DIR}chr1.fa -idx ${COMMON_DIR}hg19.idx -dbx ${COMMON_DIR}hg19.dbx

${COMMON_DIR}hg19v18.gff : ${COMMON_DIR}gencode.v18.annotation.gtf
	perl Perl/transcript_elements.pl -gtf ${COMMON_DIR}gencode.v18.annotation.gtf > ${COMMON_DIR}hg19v18.gff

