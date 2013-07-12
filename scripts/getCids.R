#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: download from PubChem all cids in a bioassay SQLite database 

library(R.utils)
library(RSQLite)
library(ChemmineR)

database = commandArgs(trailingOnly=TRUE)[1]
outfile = commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    database <- "working/bioassayDatabaseWithDomains.sqlite"
    outfile <- "working/compounds.sqlite"
}

# get cids from database
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=database)
cids <- dbGetQuery(con, "SELECT DISTINCT cid FROM activity WHERE CID NOT NULL")[[1]]
dbDisconnect(con)
cids <- as.numeric(cids)

# load structures in database 10,000 at a time 
splitCids <- split(cids, floor(1:length(cids)/10000))
outputconn <- initDb(outfile)
lapply(splitCids, function(x){
    try({
        tempSDF <- getIds(x)
        loadSdf(outputconn, tempSDF,
            function(sdfset){
                data.frame(MW = MW(sdfset, addH=TRUE))
            })
    })
}) 
# to get compounds: getCompounds(outputconn, findCompoundsByName(outputconn, c(1018, 999)))
dbDisconnect(outputconn)
