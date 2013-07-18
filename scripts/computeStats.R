#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: compute summary statistics on a new bioassay database

library(R.utils)
library(RSQLite)

database = commandArgs(trailingOnly=TRUE)[1]
outfile = commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    database <- "working/pubchemBioassay.sqlite"
    outfile <- "working/summarystats.txt"
}

# queries to run:
queries <- c(
    "select COUNT(DISTINCT aid) from activity",
    "select COUNT(DISTINCT aid) from assays",
    "select COUNT(*) from assays",
    "select COUNT(DISTINCT aid) from targets WHERE target_type = 'protein'",
    "select COUNT(DISTINCT cid) from activity",
    "SELECT COUNT(DISTINCT target) FROM targets WHERE target_type = 'protein'",
    "SELECT COUNT(DISTINCT domain) FROM domains",
    "SELECT assay_type, COUNT(*) FROM assays GROUP BY assay_type"
)

# get cids from database
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=database)
outfilehandle <- file(outfile, "wb")
lapply(queries, function(x){
    writeLines(x, outfilehandle)
    write.table(dbGetQuery(con,x), file=outfilehandle, append=T, row.names = F)
})
close(outfilehandle)
dbDisconnect(con)
