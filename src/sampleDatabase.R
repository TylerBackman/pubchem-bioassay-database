#!/usr/bin/env Rscript

# (C) 2016 Tyler WH Backman
# Purpose: build a small sample database for the bioassayR vignette

library(R.utils)
library(bioassayR)

inputDatabaseFile = commandArgs(trailingOnly=TRUE)[1]
outputSampleDatabaseFile = commandArgs(trailingOnly=TRUE)[2]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    inputDatabaseFile <- "working/pubchemBioassay.sqlite"
    outputSampleDatabaseFile <- "working/sampleDatabase.sqlite"
}

inputDatabase <- connectBioassayDB(inputDatabaseFile)
outputSampleDatabase <- newBioassayDB(outputSampleDatabaseFile, indexed=F)

addDataSource(outputSampleDatabase, description="PubChem BioAssay", version="bioassayR sample database")

# load all target 166897622 assays
assays <- queryBioassayDB(inputDatabase, "SELECT DISTINCT aid FROM targets WHERE target = '166897622'")[[1]]
for(aid in assays){
    assay <- getAssay(inputDatabase, aid)
    loadBioassay(outputSampleDatabase, assay)
}

# load aspirin (cid 2244) activity data but not whole assays
aspirinAssays <- queryBioassayDB(inputDatabase, "SELECT DISTINCT aid FROM activity WHERE cid = '2244'")[[1]]
aspirinAssays <- aspirinAssays[! aspirinAssays %in% assays]
for(aid in aspirinAssays){
    assay <- getAssay(inputDatabase, aid)
    scores(assay) <- scores(assay)[scores(assay)$cid == 2244,]
    loadBioassay(outputSampleDatabase, assay)
}

# load target translations for all targets
allTargets <- queryBioassayDB(outputSampleDatabase, "SELECT DISTINCT target FROM targets")[[1]]
allCategories <- queryBioassayDB(inputDatabase, "SELECT DISTINCT category FROM targetTranslations")[[1]]
for(category in allCategories){
    for(target in allTargets){
        translation <- translateTargetId(inputDatabase, target, category)
        if(! is.na(translation)){
            for(identifier in translation){
                loadIdMapping(outputSampleDatabase, target, category, identifier)
            }
        }
    }
}

disconnectBioassayDB(inputDatabase)
disconnectBioassayDB(outputSampleDatabase)
