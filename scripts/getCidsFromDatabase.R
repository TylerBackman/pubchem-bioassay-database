#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: download from PubChem all cids in a bioassay SQLite database 

library(R.utils)
library(RSQLite)
library(RPostgreSQL)
library(ChemmineR)

database = commandArgs(trailingOnly=TRUE)[1]
outfile = commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    database <- "working/bioassayDatabase.sqlite"
    outfile <- "working/compounds2.sqlite"
}

# get cids from database
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=database)
cids <- dbGetQuery(con, "SELECT DISTINCT cid FROM activity WHERE CID NOT NULL")[[1]]
dbDisconnect(con)
cids <- as.numeric(cids)

conn = dbConnect(dbDriver("PostgreSQL"),dbname="pubchem",host="chemminetools-2.bioinfo.ucr.edu",user="pubchem_updater",password="48ruvbvnmwejf408rfdj")

# prepare to load structures in database
outputconn <- initDb(outfile)
loadIds <- function(x){
    try({
        compoundIds = findCompoundsByName(conn,x)
        tempSDF <- getCompounds(conn,compoundIds)
        loadSdf(outputconn, tempSDF,
            function(sdfset){
                data.frame(MW = MW(sdfset, addH=TRUE))
            }
        )
    })
}

# keep retrying in smaller and smaller groups until individual compounds that won't load are identified
groupSize <- 2^13  
while(groupSize >= 1){
    print(paste("trying load with groupsize", groupSize))
    cidsInDB <- dbGetQuery(outputconn, "SELECT DISTINCT name FROM compounds WHERE name NOT NULL and name != ''")
    cidsInDB <- as.numeric(cidsInDB[,1])
    notLoaded <- setdiff(cids, cidsInDB)
    print(paste("unloaded compounds:", length(notLoaded), "out of", length(cids)))
    if(length(notLoaded) > 0){
        splitCids <- split(cids, floor(1:length(cids)/groupSize))
        lapply(splitCids, loadIds)
    } else {
        break
    }
    groupSize <- groupSize / 2
}

print(paste("final unloaded compounds:", length(notLoaded), "out of", length(cids)))

# to get compounds: getCompounds(outputconn, findCompoundsByName(outputconn, c(1018, 999)))
dbDisconnect(outputconn)
