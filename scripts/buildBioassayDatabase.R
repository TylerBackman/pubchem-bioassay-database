#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: build a bioassay SQLite database from a downloaded mirror

library(R.utils)
library(RSQLite)

bioassayMirror = commandArgs(trailingOnly=TRUE)[1]
outputDatabase = commandArgs(trailingOnly=TRUE)[2]

# bioassayMirror <- "working/bioassayMirror_test" # TEST CODE
# outputDatabase <- "working/bioassayDatabase_test.sqlite" # TEST CODE

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# create database and connect to it
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=outputDatabase)
dbGetQuery(con, "CREATE TABLE sources (source_id INTEGER PRIMARY KEY ASC, description TEXT, version TEXT)")
dbGetQuery(con, "CREATE TABLE assays (source_id INTEGER, aid INTEGER, targets TEXT, target_type TEXT, assay_type TEXT, organism TEXT)")
dbGetQuery(con, "CREATE TABLE activity (aid INTEGER, sid INTEGER, cid INTEGER, activity INTEGER, score INTEGER)")

# loop through assay CSVs and load them into the database
assaypaths <- getAssayPaths(file.path(bioassayMirror, "Data"))
for(assaypath in assaypaths){
    aid <- as.integer(gsub("^.*?(\\d+)\\.concise\\.csv.*$", "\\1", assaypath, perl = TRUE))
    print(paste("inserting activity for assay", aid))
    tempAssay <- read.csv(assaypath)[,c(1, 3, 4, 5)]
    sql <- paste("INSERT INTO activity VALUES (", aid, ", $PUBCHEM_SID, $PUBCHEM_CID, $PUBCHEM_ACTIVITY_OUTCOME, $PUBCHEM_ACTIVITY_SCORE)", sep="")
    dbBeginTransaction(con)
    dbGetPreparedQuery(con, sql, bind.data = tempAssay)
    dbCommit(con)
}

# mention source
dbGetQuery(con, paste("INSERT INTO sources VALUES (NULL, \"PubChem Bioassay\", \"", date(), "\")", sep=""))

# disconnect:
dbDisconnect(con)
