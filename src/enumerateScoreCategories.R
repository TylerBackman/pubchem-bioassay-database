#!/usr/bin/env Rscript

# (C) Tyler William H Backman
# Purpose: Enumerate PubChem BioAssay CSV header columns (score categories)
# for the full archive

library(R.utils)

bioassayMirror <- commandArgs(trailingOnly=TRUE)[1]
outputFilename <- commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
	bioassayMirror <- "working/bioassayMirror"
	outputFilename <- "working/scoreCategories.txt"
}

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# this function returns the header column names for a csv file
getHeaderNames <- function(csvFile){
  csvLines <- readLines(csvFile)
  csvLines <- csvLines[! grepl("^RESULT_", csvLines)]
  csvLines <- csvLines[! grepl("^\\s*$", csvLines)]
  if(length(csvLines) < 2){
    return(c())
  } else {
    return(strsplit(csvLines[[1]], "\\s*,\\s*")[[1]])
  }
}

# get paths for csv files 
CSVpaths <- getAssayPaths(file.path(bioassayMirror, "Data"))

# build hash table enumerating all headers
allHeaders <- new.env()
for(csvFile in CSVpaths){
  headers <- getHeaderNames(csvFile)
  for(thisHeader in headers){
    if(is.null(allHeaders[[thisHeader]])){
      allHeaders[[thisHeader]] <- 1
    } else {
      allHeaders[[thisHeader]] <- 1 + allHeaders[[thisHeader]]
    }
  }
}

# write out results
headerCounts <- sapply(ls(allHeaders), function(x) allHeaders[[x]])
headerCounts <- sort(headerCounts, decreasing=T)
write.table(headerCounts, file=outputFilename, col.names = FALSE, quote = FALSE)
