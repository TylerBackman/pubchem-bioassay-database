#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: build a bioassay SQLite database from a downloaded mirror

library(R.utils)
library(RSQLite)

bioassayMirror = commandArgs(trailingOnly=TRUE)[1]
xmlParser = commandArgs(trailingOnly=TRUE)[2]
outputDatabase = commandArgs(trailingOnly=TRUE)[3]

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# parse assay descriptions from XML files
assaypaths <- getAssayPaths(file.path(bioassayMirror, "Description"))
for(assaypath in assaypaths){
    # call as a separate script:
        # a messy hack to deal with a memory leak in the XML parser
    system(paste(xmlParser, assaypath, outputDatabase))
}
