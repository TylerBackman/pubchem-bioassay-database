library(XML)
library(RSQLite)

# create database from CSV data

# this function returns the path of each assay file within a given folder name
getAssayPaths <- function(path) {
    dirs <- list.dirs(path)
    # regex for integer_integer path
    assaydirs <- grep("\\d{7}_\\d{7}$", dirs, perl = TRUE, value = TRUE)
    list.files(assaydirs, full.names = TRUE)
}

# create database and connect to it
drv <- dbDriver("SQLite")
con <- dbConnect(drv, dbname="bioassay_database.sqlite")
dbGetQuery(con, "CREATE Table bioassay (aid INTEGER, sid INTEGER, cid INTEGER, activity INTEGER, score INTEGER, protein_target INTEGER)")

# loop through assay CSVs and load them into the database
assaypaths <- getAssayPaths("bioassay_csv_mirror_Jul_5_2011")
for(assaypath in assaypaths){
    aid <- as.integer(gsub("^.*?(\\d+)\\.concise\\.csv.*$", "\\1", assaypath, perl = TRUE))
    tempAssay <- read.csv(assaypath)
    tempAssay <- tempAssay[,c(1, 3, 4, 5)]
    tempAssay <- cbind(PUBCHEM_AID=aid, tempAssay)
    sql <- "INSERT INTO bioassay VALUES ($PUBCHEM_AID, $PUBCHEM_SID, $PUBCHEM_CID, $PUBCHEM_ACTIVITY_OUTCOME, $PUBCHEM_ACTIVITY_SCORE, NULL)"
    dbBeginTransaction(con)
    dbGetPreparedQuery(con, sql, bind.data = tempAssay)
    dbCommit(con)
}

# add protein targets from XML files
# Note: this literally takes days
assaypaths <- getAssayPaths("bioassay_desc_mirror_Jul_7_2011")
for(assaypath in assaypaths){
    aid <- as.integer(gsub("^.*?(\\d+)\\.descr\\.xml.*$", "\\1", assaypath, perl = TRUE))
    desc <- xmlTreeParse(assaypath)
    proteinID <- desc[[1]][["PC-AssayContainer"]][["PC-AssaySubmit"]][["PC-AssaySubmit_assay"]][["PC-AssaySubmit_assay_descr"]][["PC-AssayDescription"]][["PC-AssayDescription_target"]][["PC-AssayTargetInfo"]][["PC-AssayTargetInfo_mol-id"]]
    if(! is.null(proteinID)){
        proteinID <- as.integer(xmlToList(proteinID)[[1]])
        dbGetQuery(con, paste("UPDATE bioassay SET protein_target =", proteinID, "WHERE aid =", aid))
    }
}
# example query
dbGetQuery(con, "SELECT * FROM bioassay LIMIT 10")

# disconnect:
dbDisconnect(con)
