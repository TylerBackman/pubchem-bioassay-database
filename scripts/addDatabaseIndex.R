#!/usr/bin/env Rscript

# (C) 2013 Tyler WH Backman
# Purpose: index a bioassay SQLite database 

library(R.utils)
library(RSQLite)

outputDatabase = commandArgs(trailingOnly=TRUE)[1]

drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname=outputDatabase)

# add indexes
dbGetQuery(con, "CREATE UNIQUE INDEX IF NOT EXISTS assays_aid ON assays (aid)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS assays_targets ON assays (targets)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS assays_target_type ON assays (target_type)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS assays_assay_type ON assays (assay_type)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS activity_aid ON activity (aid)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS activity_cid ON activity (cid)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS activity_activity ON activity (activity)")
dbGetQuery(con, "CREATE INDEX IF NOT EXISTS activity_aid_activity ON activity (aid, activity)")

dbDisconnect(con)
