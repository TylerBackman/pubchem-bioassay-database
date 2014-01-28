#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: loads domains into database 

library(R.utils)
library(RSQLite)

targetSequences = commandArgs(trailingOnly=TRUE)[1]
domainsFromHMMScan = commandArgs(trailingOnly=TRUE)[2]
outputDatabase = commandArgs(trailingOnly=TRUE)[3]

drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=outputDatabase)

domains <- read.table(domainsFromHMMScan, header = FALSE, skip = 3)  
domains[,1] <- gsub("^(PF\\d*).*", "\\1", domains[,1], perl=TRUE)
domains[,2] <- gsub("^gi\\|(\\d*)\\|.*", "\\1", domains[,2], perl=TRUE)
colnames(domains) <- c("DOMAIN", "TARGET")

# dbGetQuery(con, "CREATE TABLE domains (domain TEXT, target INTEGER)")

sql <- "INSERT INTO domains VALUES ($DOMAIN, $TARGET)"
dbBeginTransaction(con)
dbGetPreparedQuery(con, sql, bind.data = domains)
dbCommit(con)

dbDisconnect(con)
