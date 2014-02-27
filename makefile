
all : maptools/bin/transf sjcount/sjcount

maptools/bin/transf :
	git clone https://github.com/pervouchine/maptools
	mkdir -p maptools/bin/
	make -C maptools/ all

sjcount/sjcount :
	git clone https://github.com/pervouchine/sjcount
	make -C sjcount all

