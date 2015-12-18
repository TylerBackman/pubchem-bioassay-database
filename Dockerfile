FROM bioconductor/devel_proteomics:latest
MAINTAINER Tyler Backman <tyler.backman@email.ucr.edu>
RUN printf "source(\"http://bioconductor.org/biocLite.R\")\nbiocLite(c(\"ape\",\"devtools\"))\ndevtools::install_github(\"TylerBackman/bioassayR\")\n" | R --slave
RUN apt-get update && apt-get install -y hmmer
ADD . /pubchem-bioassay-database
RUN cd /pubchem-bioassay-database && make working/summarystats.txt
