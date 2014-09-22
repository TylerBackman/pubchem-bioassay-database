#!/usr/bin/env Rscript

# (C) 2014 Tyler WH Backman
# Purpose: create EI database for all compounds in bioassay database 

library(R.utils)
library(ChemmineR)
library(bioassayR)
library(eiR)

# load openbabel (specific code for UCR Biocluster)
library(modules)
moduleload("openbabel/2.3.2")

pubchemCompoundMirror = commandArgs(trailingOnly=TRUE)[1]
database = commandArgs(trailingOnly=TRUE)[2]
eiWorkFolder = commandArgs(trailingOnly=TRUE)[3]

# test code for running without make:
if(is.null(commandArgs(trailingOnly=TRUE)[1])){
    pubchemCompoundMirror <- "working/pubchemCompoundMirror"
    database <- "working/bioassayDatabase.sqlite"
    eiWorkFolder <- "working/eiDatabase"
}

# get cids from database
db <- connectBioassayDB(database)
cids <- queryBioassayDB(db, "SELECT DISTINCT cid FROM activity WHERE CID NOT NULL")[[1]]
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
    tempSdf <- tempfile()
    write.SDF(mySdf, tempSdf)
    eiInit(tempSdf,dir=eiWorkFolder)
    unlink(tempSdf)
}
