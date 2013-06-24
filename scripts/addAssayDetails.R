#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: add XML assay details to a bioassay SQLite database from a downloaded mirror

library(R.utils)
library(RSQLite)
library(XML)
library(foreach)
library(doMC)

# setup multiprocessing options
registerDoMC(cores=8)

bioassayMirror = commandArgs(trailingOnly=TRUE)[1]
outputDatabase = commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
	bioassayMirror <- "working/bioassayMirror"
	outputDatabase <- "working/bioassayDatabaseWithAssayDetails.sqlite"
}

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# parse assay descriptions from XML files
assaypaths <- getAssayPaths(file.path(bioassayMirror, "Description"))
aids <- as.integer(gsub("^.*?(\\d+)\\.concise.descr\\.xml.*$", "\\1", assaypaths, perl = TRUE))
assaypaths <- assaypaths[! duplicated(aids)] 
aids <- aids[! duplicated(aids)]

# keep only assays which have activity data
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=outputDatabase)
dataAids <- dbGetQuery(con, "SELECT DISTINCT aid FROM activity")[,1]
assaypaths <- assaypaths[aids %in% dataAids]

# get target molecules
targetTable <- foreach(assaypath=assaypaths, .combine='rbind') %dopar% {
    aid <- as.integer(gsub("^.*?(\\d+)\\.concise.descr\\.xml.*$", "\\1", assaypath, perl = TRUE))
    xmlPointer <- xmlTreeParse(assaypath, useInternalNodes=TRUE, addFinalizer=TRUE)
    targets <- xpathSApply(xmlPointer, "//x:PC-AssayTargetInfo_mol-id/text()", xmlValue, namespaces="x")
    targetTypes <- xpathSApply(xmlPointer,"//x:PC-AssayTargetInfo_molecule-type/@value", namespaces="x")
    free(xmlPointer)
    if(is.null(targets)){
	return(NULL)
    } else {
        return(cbind(aid, targets, targetTypes))
    }
}

# load target molecules
dbGetQuery(con, "CREATE TABLE targets (aid INTEGER, target TEXT, target_type TEXT)")
colnames(targetTable) <- c("AID", "TARGET", "TARGET_TYPE")
targetTable <- as.data.frame(targetTable)
sql <- "INSERT INTO targets VALUES ($AID, $TARGET, $TARGET_TYPE)"
dbBeginTransaction(con)
dbGetPreparedQuery(con, sql, bind.data = targetTable)
dbCommit(con)

# get other assay details
parsedTable <- foreach(assaypath=assaypaths, .combine='rbind') %dopar% {
    aid <- as.integer(gsub("^.*?(\\d+)\\.concise.descr\\.xml.*$", "\\1", assaypath, perl = TRUE))
    xmlPointer <- xmlTreeParse(assaypath, useInternalNodes=TRUE, addFinalizer=TRUE)
    type <- xpathSApply(xmlPointer, "//x:PC-AssayDescription_activity-outcome-method/@value", namespaces="x")[[1]]
    if(is.null(type)){
	type <- NA
    }
    free(xmlPointer)
    cbind(aid, type)
}

# load other assay details
dbGetQuery(con, "CREATE TABLE assays (source_id INTEGER, aid INTEGER, assay_type TEXT)")
colnames(parsedTable) <- c("AID", "ASSAY_TYPE")
parsedTable <- as.data.frame(parsedTable)
sql <- "INSERT INTO assays VALUES (1, $AID, $ASSAY_TYPE)"
dbBeginTransaction(con)
dbGetPreparedQuery(con, sql, bind.data = parsedTable)
dbCommit(con)

dbDisconnect(con)
#     organism <- desc[[1]][["PC-AssaySubmit_assay"]][["PC-AssaySubmit_assay_descr"]][["PC-AssayDescription"]][["PC-AssayDescription_target"]][["PC-AssayTargetInfo"]][["PC-AssayTargetInfo_organism"]][["BioSource"]][["BioSource_org"]][["Org-ref"]][["Org-ref_orgname"]][["OrgName"]][["OrgName_name"]][["OrgName_name_binomial"]][["BinomialOrgName"]][["BinomialOrgName_genus"]]  
