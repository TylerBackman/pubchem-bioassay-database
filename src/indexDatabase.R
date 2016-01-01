#!/usr/bin/env Rscript

# (C) 2015 Tyler WH Backman
# Purpose: enable indexing on a bioassayDB database

library(R.utils)
library(bioassayR)

outputDatabase = commandArgs(trailingOnly=TRUE)[1]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    outputDatabase <- "working/bioassayDatabaseWithSpecies.sqlite"
}

db <- connectBioassayDB(outputDatabase, writeable=T)

# store temp files in memory in case disk space is limited
queryBioassayDB(db, "PRAGMA temp_store = 2")

addBioassayIndex(db)
disconnectBioassayDB(db)
