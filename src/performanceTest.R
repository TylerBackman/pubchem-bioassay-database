#!/usr/bin/env Rscript

# (C) 2016 Tyler WH Backman
# Purpose: test performance of bioassayR and build an output table

library(R.utils)
library(bioassayR)
library(foreach)
library(ChemmineR)
library(xtable)

# inputDatabaseFile = commandArgs(trailingOnly=TRUE)[1]
# outputSampleDatabaseFile = commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    inputDatabaseFile <- "/dev/shm/pubchem_protein_only.sqlite"
    ramdisk <- "/dev/shm"
    parsedPaths <- "working/parsedPaths.RData"
    outputTable <- "working/performance.tex"
    # outputSampleDatabaseFile <- "working/sampleDatabase.sqlite"
}

inputDatabase <- connectBioassayDB(inputDatabaseFile)

# get aid of a 10k+ compound assay
largeAssay <- queryBioassayDB(inputDatabase, "SELECT aid, COUNT(DISTINCT cid) AS size FROM activity GROUP BY aid LIMIT 100")
largeAssay <- largeAssay[largeAssay[,2] > 10000,]
aid <- largeAssay[1,1]

# get file paths
load(parsedPaths)
XMLpath <- XMLpaths[XMLaids %in% aid]
CSVpath <- CSVpaths[CSVaids %in% aid]

# copy the large assay files to ramdisk
RDXMLpath <- file.path(ramdisk, "rdxml.xml")
RDCSVpath <- file.path(ramdisk, "rdcsv.csv")
file.copy(XMLpath, RDXMLpath)
file.copy(CSVpath, RDCSVpath)

# get first numeric line number for CSV
csvLines <- readLines(RDCSVpath)
firstLine <- grep("^\\d", csvLines)[1]

# get 10k highly screened random compounds
# highlyScreened <- screenedAtLeast(inputDatabase, 10)
highlyScreened <- readLines("/rhome/tbackman/Projects/bioactivityQuestions/working/highlyScreenedCids.txt")
highlyScreened <- as.numeric(highlyScreened)
randomizedhighlyScreened <- sample(highlyScreened)

sizes <- c(1, 100, 1000, 10000)
result <- foreach(i=sizes, .combine="rbind") %do%{
    # measure parse time
    writeLines(csvLines[1:(i+firstLine-1)], file.path(ramdisk, "short.csv"))
    parseTime <- system.time(
        myAssay <- parsePubChemBioassay(aid, file.path(ramdisk, "short.csv"), RDXMLpath)
    )[["elapsed"]]
    unlink(file.path(ramdisk, "short.csv"))

    # measure database load time
    myDatabaseFilename <- file.path(ramdisk, "sample.db")
    mydb <- newBioassayDB(myDatabaseFilename, indexed=FALSE)
    addDataSource(mydb, description="PubChem BioAssay", version="unknown")
    loadTime <- system.time(
        loadBioassay(mydb, myAssay)
    )[["elapsed"]]
    disconnectBioassayDB(mydb)
    unlink(myDatabaseFilename)

    # measure finding active targets for compounds
    cidList <- randomizedhighlyScreened[1:i]
    activeTime <- system.time(
        activeTargetList <- lapply(cidList, activeTargets, database=inputDatabase)
    )[["elapsed"]]

    # measure creating bioassaySet
    setTime <- system.time(
        myAssaySet <- getBioassaySetByCids(inputDatabase, cidList)
    )[["elapsed"]]

    # time fingerprint generation
    fpTime <- system.time(
        myFp <- bioactivityFingerprint(bioassaySet=myAssaySet)
    )[["elapsed"]]

    # time fpsim search
    query <- myFp[[1]]
    searchTime <- system.time(
        searchResult <- fpSim(query,myFp)
    )[["elapsed"]]

    return(c(parseTime, loadTime, activeTime, setTime, fpTime, searchTime))
}

disconnectBioassayDB(inputDatabase)

result <- t(result)
row.names(result) <- c("Parsing assay", "Loading assay", "Finding active targets", "Building bioassaySet by cids","Building fingerprint", "Fingerprint search")
colnames(result) <- sizes

tableText <- xtable(result)
print.xtable(tableText, file=outputTable)
