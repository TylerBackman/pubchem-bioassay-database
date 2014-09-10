#!/usr/bin/env Rscript

# (C) 2014 Tyler WH Backman
# Purpose: compute atom pairs for all highly screened compounds in database 
#           designed to run in parallel on an mpi cluster

library(R.utils)
library(ChemmineR)
library(bioassayR)
library(foreach)
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
cids <- queryBioassayDB(db, "SELECT DISTINCT cid FROM activity WHERE CID NOT NULL")[[1]]
cids <- as.numeric(cids)
disconnectBioassayDB(db)

# get paths of all SDF files in PubChem
sdfs <- list.files(pubchemCompoundMirror, full.names = TRUE)
sdfs <- sdfs[grep(".sdf.gz$", sdfs)]

# launch cluster
cl <- makeCluster(nodes, type = "MPI") 
registerDoSNOW(cl)

# combine function to drop "FALSE" results
combineAtomPairs <- function(ap1, ap2){
    if(! is.logical(ap2)) return(c(ap1, ap2))
    return(ap1)
}

# compute atom pairs in parallel on cluster
results <- foreach(i = sdfs, .combine='combineAtomPairs', .inorder=TRUE) %dopar% {
    lowerLimit <- as.numeric(gsub("^.*Compound_(\\d+)_(\\d+).sdf.gz", "\\1", i))
    higherLimit <- as.numeric(gsub("^.*Compound_(\\d+)_(\\d+).sdf.gz", "\\2", i))
    cidSubset <- cids[cids <= higherLimit]
    cidSubset <- cidSubset[cidSubset >= lowerLimit]
    if(length(cidSubset) == 0) return(FALSE)    
    library(ChemmineR)
    mySdf <- read.SDFset(i)
    mySdf <- mySdf[validSDF(mySdf)]
    if(length(mySdf) == 0) return(FALSE)    
    mySdf <- mySdf[sdfid(mySdf) %in% cidSubset]
    if(length(mySdf) == 0) return(FALSE)    
    ap <- sdf2ap(mySdf)
    cid(ap) <- sdfid(mySdf)
    return(as(ap, "list"))
}

# save results and quit
stopCluster(cl)
results <- as(results, "APset")
save(list = c("results"), file = outfile)
