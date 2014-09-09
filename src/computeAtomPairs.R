#!/usr/bin/env Rscript

# (C) 2014 Tyler WH Backman
# Purpose: compute atom pairs for all highly screened compounds in database 
#           designed to run in parallel on an mpi cluster

library(R.utils)
library(ChemmineR)
library(bioassayR)
library(foreach)
library(modules) # if you don't have this, run install.packages("/home_girkelab/tbackman/Projects/modules4R/modules_1.0.tar.gz", repos=NULL)
moduleload("openmpi")
library(snow)
library(doSNOW)

database = commandArgs(trailingOnly=TRUE)[1]
pubchemCompoundMirror = commandArgs(trailingOnly=TRUE)[2]
outfile = commandArgs(trailingOnly=TRUE)[3]

# test code for running without make:
if(is.null(commandArgs(trailingOnly=TRUE)[1])){
    database <- "working/bioassayDatabase.sqlite"
    pubchemCompoundMirror <- "working/pubchemCompoundMirror"
    outfile <- "working/ap.rda"
}

# setup variables
nodes <- 16 

# get cids from database
db <- connectBioassayDB(database)
cids <- queryBioassayDB(db, "SELECT DISTINCT cid FROM activity WHERE CID NOT NULL LIMIT 10")[[1]]
cids <- as.numeric(cids)
disconnectBioassayDB(db)

# get paths of all SDF files in PubChem
sdfs <- list.files(pubchemCompoundMirror, full.names = TRUE)
sdfs <- sdfs[grep(".sdf.gz$", sdfs)]

# launch cluster
cl <- makeCluster(nodes, type = "MPI") 
registerDoSNOW(cl)

# compute atom pairs in parallel on cluster
results <- foreach(i = sdfs, .combine='c') %dopar% {
    lowerLimit <- as.numeric(gsub("^.*Compound_(\\d+)_(\\d+).sdf.gz", "\\1", i))
    higherLimit <- as.numeric(gsub("^.*Compound_(\\d+)_(\\d+).sdf.gz", "\\2", i))
    cidSubset <- cids[cids <= higherLimit]
    cidSubset <- cidSubset[cidSubset >= lowerLimit]
    if(length(cidSubset) == 0) return(FALSE)    
    mySdf <- read.SDFset(i)
    mySdf <- mySdf[validSDF(mySdf)]
    if(length(mySdf) == 0) return(FALSE)    
    mySdf <- mySdf[sdfid(mySdf) %in% cidSubset]
    if(length(mySdf) == 0) return(FALSE)    
    ap <- sdf2ap(mySdf)
    cid(ap) <- sdfid(mySdf)
    return(ap)
}

stopCluster(cl)
save(list = ls(all=TRUE), file = outfile)
