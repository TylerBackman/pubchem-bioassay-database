#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: build a bioassay SQLite database from a downloaded mirror

library(R.utils)
library(RSQLite)

bioassayMirror <- commandArgs(trailingOnly=TRUE)[1]
outputDatabase <- commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
	bioassayMirror <- "working/bioassayMirror"
	outputDatabase <- "working/bioassayDatabase.sqlite"
}

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
dbGetQuery(con, "CREATE TABLE activity (aid INTEGER, cid INTEGER, sid INTEGER, activity INTEGER, score INTEGER)")

# loop through assay CSVs and load them into the database
assaypaths <- getAssayPaths(file.path(bioassayMirror, "Data"))
aids <- as.integer(gsub("^.*?(\\d+)\\.concise\\.csv.*$", "\\1", assaypaths, perl = TRUE))
assaypaths <- assaypaths[! duplicated(aids)]
for(assaypath in assaypaths){
    aid <- as.integer(gsub("^.*?(\\d+)\\.concise\\.csv.*$", "\\1", assaypath, perl = TRUE))
    tempAssay <- read.csv(assaypath)[,c("PUBCHEM_CID", "PUBCHEM_SID", "PUBCHEM_ACTIVITY_OUTCOME", "PUBCHEM_ACTIVITY_SCORE")]
    if(nrow(tempAssay) < 1){
        print(paste("not inserting empty assay:", aid))
        next
    }
    outcomes <- rep(NA, nrow(tempAssay))
    outcomes[tempAssay[,"PUBCHEM_ACTIVITY_OUTCOME"] == "Active"] <- 1   
    outcomes[tempAssay[,"PUBCHEM_ACTIVITY_OUTCOME"] == 1] <- 0   
    outcomes[tempAssay[,"PUBCHEM_ACTIVITY_OUTCOME"] == "Inactive"] <- 0   
    outcomes[tempAssay[,"PUBCHEM_ACTIVITY_OUTCOME"] == 2] <- 1   
    if(! FALSE %in% (is.na(outcomes))){
        print(paste("skipping assay without activity:", aid))
        next
    }
    tempAssay[,"PUBCHEM_ACTIVITY_OUTCOME"] <- outcomes
#   Uncomment to avoid adding NA activity data:
#   tempAssay <- tempAssay[! is.na(tempAssay[,"PUBCHEM_ACTIVITY_OUTCOME"]),]
    print(paste("inserting activity for assay", aid))
    sql <- paste("INSERT INTO activity VALUES (", aid, ", $PUBCHEM_CID, $PUBCHEM_SID, $PUBCHEM_ACTIVITY_OUTCOME, $PUBCHEM_ACTIVITY_SCORE)", sep="")
    dbBeginTransaction(con)
    dbGetPreparedQuery(con, sql, bind.data = tempAssay)
    dbCommit(con)
}

# mention source
dbGetQuery(con, paste("INSERT INTO sources VALUES (NULL, \"PubChem Bioassay\", \"", date(), "\")", sep=""))

# disconnect:
dbDisconnect(con)
