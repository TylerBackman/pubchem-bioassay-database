#!/bin/bash

# Purpose: makes a mirror of pubchem bioassay in the specified folder 
# (C) Tyler WH Backman

cd $1
wget ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/README

mkdir Description
cd Description
wget -r -nd ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Description/
cd ..

mkdir Data
cd Data
wget -r -nd ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/CSV/Data/
unzip "*.zip"
rm -f *.zip

cd ../Description
unzip "*.zip"
rm -f *.zip
