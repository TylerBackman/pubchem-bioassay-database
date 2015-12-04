FROM bioconductor/release_proteomics:20150202
MAINTAINER Tyler Backman <tyler.backman@email.ucr.edu>
RUN printf "source(\"http://bioconductor.org/biocLite.R\")\nbiocLite(c(\"ape\"))\n" | R --slave
ADD . /pubchem-bioassay-database
RUN cd /pubchem-bioassay-database && make working/summarystats.txt
