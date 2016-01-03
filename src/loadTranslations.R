#!/usr/bin/env Rscript

# (C) 2016 Tyler William H Backman
# Purpose: load annotation data into database

library(R.utils)
library(bioassayR)

translations <- commandArgs(trailingOnly=TRUE)[1]
clusteringResultFolder <- commandArgs(trailingOnly=TRUE)[2]
domainsFromHMMScanFile <- commandArgs(trailingOnly=TRUE)[3]
databaseFile <- commandArgs(trailingOnly=TRUE)[4]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    translations <- "working/gi_uniprot_mapping.dat"
    clusteringResultFolder <- "working/targetClusters"
    domainsFromHMMScanFile <- "working/domainsFromHmmscanTwoCols"
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

# load domain data
domains <- read.table(domainsFromHMMScanFile, header = FALSE)
domains[,1] <- gsub("^(PF\\d*).*", "\\1", domains[,1], perl=TRUE)
domains[,2] <- gsub("^gi\\|(\\d*)\\|.*", "\\1", domains[,2], perl=TRUE)
colnames(domains) <- c("DOMAIN", "TARGET")
mapply(function(domain, target){
    loadIdMapping(database, target, "domains", domain)
}, domains$DOMAIN, domains$TARGET)

disconnectBioassayDB(database)
