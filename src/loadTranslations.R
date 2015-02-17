#!/usr/bin/env Rscript

# (C) 2015 Tyler William H Backman
# Purpose: load raw data to translate genbank GIs into uniprot IDs
#   skip entries that don't have targets already loaded in database

library(R.utils)
library(bioassayR)

translations <- commandArgs(trailingOnly=TRUE)[1]
databaseFile <- commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    translations <- "working/gi_uniprot_mapping.dat"
    databaseFile <- "working/databaseWithTargetTranslations.sqlite"
}

database <- connectBioassayDB(databaseFile, writable = TRUE)
allTargets <- queryBioassayDB(database, "SELECT DISTINCT target FROM targets")[[1]]
con  <- file(translations, open = "r")
while (length(oneLine <- readLines(con, n = 1, warn = FALSE)) > 0) {
    splitLine <- strsplit(oneLine, split="\t")[[1]]
    if(splitLine[3] %in% allTargets){
        loadTranslation(database, splitLine[3], "UniProt", splitLine[1])
    }
}
close(con)
disconnectBioassayDB(database)
