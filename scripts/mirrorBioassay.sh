#!/bin/bash

# Purpose: makes a mirror of pubchem bioassay in the current working directory
# (C) 2013 Tyler WH Backman

cd $1
wget ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/Concise/CSV/README

mkdir Description
cd Description
wget -r -nd ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/Concise/CSV/Description/
cd ..

mkdir Data
cd Data
wget -r -nd ftp://ftp.ncbi.nlm.nih.gov/pubchem/Bioassay/Concise/CSV/Data/
unzip "*.zip"
rm -f *.zip

cd ../Description
unzip "*.zip"
rm -f *.zip
cd ..
