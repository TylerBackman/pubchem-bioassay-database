#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: compute summary statistics on a new bioassay database

library(R.utils)
library(RSQLite)

database = commandArgs(trailingOnly=TRUE)[1]
bioassayMirror = commandArgs(trailingOnly=TRUE)[2]
outfile = commandArgs(trailingOnly=TRUE)[3]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    database <- "working/pubchemBioassay.sqlite"
    bioassayMirror <- "working/bioassayMirror"
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
dbDisconnect(con)

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# get paths for all csv files 
CSVpaths <- getAssayPaths(file.path(bioassayMirror, "Data"))
CSVaids <- as.integer(gsub("^.*?(\\d+)\\.concise\\.csv.*$", "\\1", CSVpaths, perl = TRUE))
CSVpaths <- CSVpaths[! duplicated(CSVaids)]
CSVaids <- CSVaids[! duplicated(CSVaids)]

# count all compounds
cidEnv <- new.env(hash = TRUE)
for(x in CSVpaths){
    tempAssay <- read.csv(x)[,c("PUBCHEM_CID", "PUBCHEM_ACTIVITY_OUTCOME", "PUBCHEM_ACTIVITY_SCORE")] 
    cids <- unique(tempAssay$PUBCHEM_CID)
    cids <- cids[! is.na(cids)]
    cids <- as.character(cids)
    for(y in cids){
        assign(y, value="", envir=cidEnv)
    }
}
allCids <- ls(cidEnv)
allCids <- allCids[! is.na(allCids)]

writeLines(paste("Total unique cids:", length(allCids)), outfilehandle)
writeLines(paste("Total unique assays:", length(CSVaids)), outfilehandle)
close(outfilehandle)
