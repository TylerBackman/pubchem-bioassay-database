#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: connect to genbank to get correct species names for each 
#           protein target


library(R.utils)
library(RSQLite)
library(ape)

outputDatabase = commandArgs(trailingOnly=TRUE)[1]

# test code for running without make:
if(is.na(commandArgs(trailingOnly=TRUE)[1])){
    outputDatabase <- "working/bioassayDatabaseWithSpecies.sqlite"
}

drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=outputDatabase)

targets <- dbGetQuery(con, "SELECT DISTINCT target FROM targets WHERE target NOT NULL and target_type = 'protein'")[,1]
targetSequences <- read.GenBank(targets, species.names = TRUE)
targetSpecies <- attr(targetSequences, "species")

proteinAssays <- dbGetQuery(con, "SELECT aid, target FROM targets WHERE target NOT NULL and target_type = 'protein'")

assaySpecies <- merge(x=proteinAssays, y=cbind(targets, targetSpecies), all.x=T, by.x=2, by.y=1)[,2:3]
colnames(assaySpecies) <- c("AID", "ORGANISM")

sql <- "UPDATE assays SET organism=$ORGANISM WHERE aid=$AID"
dbBeginTransaction(con)
dbGetPreparedQuery(con, sql, bind.data = assaySpecies)
dbCommit(con)

dbDisconnect(con)
