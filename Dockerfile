FROM bioconductor/bioconductor_docker:latest
MAINTAINER Tyler Backman <TBackman@lbl.gov>
# Update Bioconductor packages from devel version
RUN Rscript --vanilla -e "options(repos = c(CRAN = 'https://cran.r-project.org')); BiocManager::install(ask=FALSE)"
# Install required Bioconductor packages from devel version
RUN Rscript -e 'BiocManager::install("bioassayR")'
RUN Rscript -e 'install.packages("R.utils")'
RUN apt-get update && apt-get install -y hmmer
ADD . /pubchem-bioassay-database
RUN cd /pubchem-bioassay-database && make working/summarystats.txt