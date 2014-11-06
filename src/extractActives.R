#!/usr/bin/env Rscript

# (C) 2014 Tyler WH Backman
# Purpose: create SDF file of all compounds which show activity in a bioassayR
#           database

library(R.utils) 
library(ChemmineR)
library(bioassayR)

pubchemCompoundMirror = commandArgs(trailingOnly=TRUE)[1]
database = commandArgs(trailingOnly=TRUE)[2]
outputFile = commandArgs(trailingOnly=TRUE)[3]

# test code for running without make:
if(is.null(commandArgs(trailingOnly=TRUE)[1])){
    pubchemCompoundMirror <- "working/pubchemCompoundMirror"
    database <- "working/bioassayDatabase.sqlite"
    outputFile <- "working/activeCompounds.sdf"
}

# delete output file if it already exists
unlink(outputFile)

# get cids from database
db <- connectBioassayDB(database)
cids <- queryBioassayDB(db, "SELECT DISTINCT cid FROM activity WHERE CID NOT NULL AND activity = 1")[[1]]
cids <- as.numeric(cids)
disconnectBioassayDB(db)

# get paths of all SDF files in PubChem
sdfs <- list.files(pubchemCompoundMirror, full.names = TRUE)
sdfs <- sdfs[grep(".sdf.gz$", sdfs)]

# add compounds to EI database one file at a time
for (i in sdfs) {
    lowerLimit <- as.numeric(gsub("^.*Compound_(\\d+)_(\\d+).sdf.gz", "\\1", i))
    higherLimit <- as.numeric(gsub("^.*Compound_(\\d+)_(\\d+).sdf.gz", "\\2", i))
    cidSubset <- cids[cids <= higherLimit]
    cidSubset <- cidSubset[cidSubset >= lowerLimit]
    if(length(cidSubset) == 0) next    
    mySdf <- read.SDFset(i)
    mySdf <- mySdf[validSDF(mySdf)]
    if(length(mySdf) == 0) next    
    mySdf <- mySdf[sdfid(mySdf) %in% cidSubset]
    if(length(mySdf) == 0) next  

    # append 'mySdf' to 'outputFile'
    fileConn<-file(outputFile, open="a")
    for(i in seq(along=mySdf)){
        sdf <- sdf2str(mySdf[[i]])
        sdf <- paste(sdf, collapse="\n")
        writeLines(sdf, fileConn)
    }
    close(fileConn)
    # get memory back
    rm(mySdf)
    gc()
}
