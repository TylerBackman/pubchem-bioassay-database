#!/usr/bin/env Rscript

# (C) 2015 Tyler William H Backman
# Purpose: load raw data to translate genbank GIs into uniprot IDs and clusters
#   skip entries that don't have targets already loaded in database

library(R.utils)
library(bioassayR)

translations <- commandArgs(trailingOnly=TRUE)[1]
clusteringResultFolder <- commandArgs(trailingOnly=TRUE)[2]
databaseFile <- commandArgs(trailingOnly=TRUE)[3]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    translations <- "working/gi_uniprot_mapping.dat"
    clusteringResultFolder <- "working/targetClusters"
    databaseFile <- "working/databaseWithTargetTranslations.sqlite"
}

# load mapping for UniProt translations
database <- connectBioassayDB(databaseFile, writeable = TRUE)
allTargets <- queryBioassayDB(database, "SELECT DISTINCT target FROM targets")[[1]]
con  <- file(translations, open = "r")
while (length(oneLine <- readLines(con, n = 1, warn = FALSE)) > 0) {
    splitLine <- strsplit(oneLine, split="\t")[[1]]
    if(splitLine[3] %in% allTargets){
        loadIdMapping(database, splitLine[3], "UniProt", splitLine[1])
    }
}
close(con)

# load kClust clustering data
clusters <- read.table(file.path(clusteringResultFolder, "clusters.dmp"), skip=1)
clusterHeaders <- readLines(file.path(clusteringResultFolder, "headers.dmp"))
clusterHeaders <- gsub("^\\d+\\s+(.*)$", "\\1", clusterHeaders, perl = TRUE)
clusterHeaders <- gsub("^>gi\\|(\\d+).*$", "\\1", clusterHeaders, perl = TRUE)
clusters <- cbind2(clusterHeaders, clusters[,2])
mapply(function(gi, clusterId){
    loadIdMapping(database, gi, "kClust", clusterId)
}, clusters[,1], clusters[,2])

disconnectBioassayDB(database)
