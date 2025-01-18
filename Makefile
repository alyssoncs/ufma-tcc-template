.PHONY: all clean cleanall

all:
	latexmk

continuous:
	latexmk -pvc

clean:
	latexmk -c
	rm -rf build/

cleanall: clean
	latexmk -C
	rm -rf build/
	rm -rf output/

