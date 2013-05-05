#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: add XML assay details to a bioassay SQLite database from a downloaded mirror

library(R.utils)
library(RSQLite)
library(XML)

bioassayMirror = commandArgs(trailingOnly=TRUE)[1]
outputDatabase = commandArgs(trailingOnly=TRUE)[2]

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# parse assay descriptions from XML files
assaypaths <- getAssayPaths(file.path(bioassayMirror, "Description"))
parsedTable <- t(sapply(assaypaths, function(assaypath){
    aid <- as.integer(gsub("^.*?(\\d+)\\.concise.descr\\.xml.*$", "\\1", assaypath, perl = TRUE))
    print(paste("parsing XML details for assay", aid))

    xmlPointer <- xmlTreeParse(assaypath, useInternalNodes=TRUE, addFinalizer=TRUE)
    desc <- xmlRoot(xmlPointer, addFinalizer = TRUE)
    free(xmlPointer)

    target <- desc[[1]][["PC-AssaySubmit_assay"]][["PC-AssaySubmit_assay_descr"]][["PC-AssayDescription"]][["PC-AssayDescription_target"]][["PC-AssayTargetInfo"]][["PC-AssayTargetInfo_mol-id"]]
    if(! is.null(target)){
        target <- xmlToList(target)[[1]]
    } else {
        target <- NA
    }
    targetType <- desc[[1]][["PC-AssaySubmit_assay"]][["PC-AssaySubmit_assay_descr"]][["PC-AssayDescription"]][["PC-AssayDescription_target"]][["PC-AssayTargetInfo"]][["PC-AssayTargetInfo_molecule-type"]]
    if(! is.null(targetType)){
        targetType <- xmlToList(targetType)$.attrs[["value"]]
    } else if(! is.na(target)){
        targetType <- "protein"
    } else {
        targetType <- NA
    }
    assayType <- desc[[1]][["PC-AssaySubmit_assay"]][["PC-AssaySubmit_assay_descr"]][["PC-AssayDescription"]][["PC-AssayDescription_activity-outcome-method"]]
    if(! is.null(assayType)){
        assayType <- xmlToList(assayType)$.attrs[["value"]]
    } else {
        assayType <- NA
    }
    organism <- desc[[1]][["PC-AssaySubmit_assay"]][["PC-AssaySubmit_assay_descr"]][["PC-AssayDescription"]][["PC-AssayDescription_target"]][["PC-AssayTargetInfo"]][["PC-AssayTargetInfo_organism"]][["BioSource"]][["BioSource_org"]][["Org-ref"]][["Org-ref_orgname"]][["OrgName"]][["OrgName_name"]][["OrgName_name_binomial"]][["BinomialOrgName"]][["BinomialOrgName_genus"]]  
    if(! is.null(organism)){
        organism <- xmlToList(organism)[[1]]
    } else {
        organism <- NA
    }
    cbind(aid, target, targetType, assayType, organism)
}))

print("loading results into database")
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=outputDatabase)

colnames(parsedTable) <- c("AID", "TARGETS", "TARGET_TYPE", "ASSAY_TYPE", "ORGANISM")
parsedTable <- as.data.frame(parsedTable)
sql <- "INSERT INTO assays VALUES (1, $AID, $TARGETS, $TARGET_TYPE, $ASSAY_TYPE, $ORGANISM)"
dbBeginTransaction(con)
dbGetPreparedQuery(con, sql, bind.data = parsedTable)
dbCommit(con)

dbDisconnect(con)
