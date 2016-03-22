#!/usr/bin/env Rscript

# (C) Tyler WH Backman
# Purpose: build a PubChem BioAssay SQLite database from a downloaded CSV mirror

library(R.utils)
library(bioassayR)

bioassayMirror <- commandArgs(trailingOnly=TRUE)[1]
targetType <- commandArgs(trailingOnly=TRUE)[2]
outputDatabase <- commandArgs(trailingOnly=TRUE)[3]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
	bioassayMirror <- "working/bioassayMirror"
    targetType <- "proteinsOnly"
	outputDatabase <- "working/bioassayDatabase.sqlite"
}

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# bash commands to make test folder
# cd working
# mkdir -p bioassayMirror_test/Data/0575001_0576000/
# cp -a bioassayMirror/Data/0575001_0576000/57511* bioassayMirror_test/Data/0575001_0576000/
# mkdir -p bioassayMirror_test/Description/0575001_0576000/
# cp -a bioassayMirror/Description/0575001_0576000/57511* bioassayMirror_test/Description/0575001_0576000/
# rm bioassayMirror_test/Data/0575001_0576000/575111.csv.gz
# rm bioassayMirror_test/Description/0575001_0576000/575115.concise.descr.xml.gz

# create database and connect to it
database <- newBioassayDB(outputDatabase, writeable = TRUE, indexed = FALSE)

# get paths for csv files 
CSVpaths <- getAssayPaths(file.path(bioassayMirror, "Data"))
CSVaids <- as.integer(gsub("^.*?(\\d+)\\.csv.*$", "\\1", CSVpaths, perl = TRUE))
CSVpaths <- CSVpaths[! duplicated(CSVaids)]
CSVaids <- CSVaids[! duplicated(CSVaids)]

# get paths for XML files
XMLpaths <- getAssayPaths(file.path(bioassayMirror, "Description"))
XMLaids <- as.integer(gsub("^.*?(\\d+)\\.descr\\.xml.*$", "\\1", XMLpaths, perl = TRUE))
XMLpaths <- XMLpaths[! duplicated(XMLpaths)]
XMLaids <- XMLaids[! duplicated(XMLpaths)]

# keep only common paths, and order together
intersection <- intersect(CSVaids, XMLaids)
CSVpaths <- CSVpaths[CSVaids %in% intersection]
CSVaids <- CSVaids[CSVaids %in% intersection]
XMLpaths <- XMLpaths[XMLaids %in% intersection]
XMLaids <- XMLaids[XMLaids %in% intersection]
CSVpaths <- CSVpaths[match(CSVaids, XMLaids)]
CSVaids <- CSVaids[match(CSVaids, XMLaids)]

# add data source
addDataSource(database, "PubChem BioAssay", format(Sys.time(), "%b %d %Y"))

# loop through assay files and load them into the database
mapply(function(aid, csvFile, XMLFile){
        print(paste("loading assay:", aid))
        assay <- parsePubChemBioassay(aid, csvFile, XMLFile)
        
        if(nrow(scores(assay)) < 1){
            print(paste("skipping empty assay:", aid))
            return() 
        }
        if(! FALSE %in% (is.na(scores(assay)$activity))){
            print(paste("skipping assay without activity:", aid))
            return() 
        }
        if((targetType == "proteinsOnly") && !("protein" %in% target_types(assay))){
            print(paste("skipping assay without a protein target:", aid))
            return()
        }
        loadBioassay(database, assay)
    },
    CSVaids,
    CSVpaths,
    XMLpaths)

# disconnect from database
disconnectBioassayDB(database)
