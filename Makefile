mpiCores = 1 
all: working/kClust working/pubchemBioassay.sqlite working/compounds.sqlite working/summarystats.txt

clean:
	rm -rf working/*

##########################################
# download external dependencies 
# Note: all external files should go here
##########################################

working/mayachemtools/bin/SplitSDFiles.pl:
	wget http://www.mayachemtools.org/download/mayachemtools.tar.gz -O working/mayachemtools.tar.gz
	tar xvfz working/mayachemtools.tar.gz -C working/

# download uniprot ID mappings
working/uniprot_id_mapping.dat.gz:
	mkdir -p working
	wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping/idmapping.dat.gz -O $@

working/targets.fasta: working/bioassayDatabase.sqlite
	echo "SELECT DISTINCT target FROM targets WHERE target_type = \"protein\";" | sqlite3 $< | xargs -I '{}' wget -O - "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id={}&rettype=fasta&retmode=text" >> $@

working/Pfam-A.hmm:
	wget -O $@.gz ftp://ftp.sanger.ac.uk/pub/databases/Pfam/releases/Pfam27.0/Pfam-A.hmm.gz
	gunzip $@.gz
	hmmpress $@

# download all of PubChem Compound
working/pubchemCompoundMirror:
	mkdir -p $@
	wget -r -nd ftp://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/ -P $@

##########################################
# build database
##########################################

# extract GI-> uniprot ID mappings to uncompressed text file
working/gi_uniprot_mapping.dat: working/uniprot_id_mapping.dat.gz
	zcat $< | awk '{if ($$2 == "GI") print $$0;}' > $@

working/bioassayMirror: src/mirrorBioassay.sh
	mkdir -p $@
	$^ $@
	
working/bioassayDatabase.sqlite: src/buildBioassayDatabase.R working/bioassayMirror
	$^ proteinsOnly $@

working/domainsFromHmmscan: working/Pfam-A.hmm working/targets.fasta
	hmmscan --tblout working/domainsFromHmmscan --cpu 8 --noali $^

working/domainsFromHmmscanTwoCols: working/domainsFromHmmscan
	awk '{print $$2 " " $$3}' $^ > $@

working/bioassayDatabaseWithDomains.sqlite: src/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols working/bioassayDatabase.sqlite
	cp working/bioassayDatabase.sqlite $@
	src/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols $@

working/databaseWithTargetTranslations.sqlite: src/loadTranslations.R working/bioassayDatabaseWithDomains.sqlite working/gi_uniprot_mapping.dat
	cp working/bioassayDatabaseWithDomains.sqlite $@
	$< working/gi_uniprot_mapping.dat $@

working/indexedBioassayDatabase.sqlite: working/databaseWithTargetTranslations.sqlite 
	cp $< $@
	echo "CREATE INDEX IF NOT EXISTS activity_cid ON activity (cid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS activity_aid ON activity (aid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS targets_aid ON targets (aid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS targets_target ON targets (target);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS targetTranslations_target ON targetTranslations (target);" | sqlite3 $@

working/bioassayDatabaseWithSpecies.sqlite: src/annotateSpecies.R working/indexedBioassayDatabase.sqlite
	cp working/indexedBioassayDatabase.sqlite $@
	$< $@

working/bioassayDatabaseNoDuplicates.sqlite: working/bioassayDatabaseWithSpecies.sqlite
	cp $< /dev/shm/bioassayDatabaseNoDuplicates.sqlite
	echo "DELETE FROM activity WHERE rowid NOT IN (SELECT min(rowid) FROM activity GROUP BY aid, cid);" | sqlite3 /dev/shm/bioassayDatabaseNoDuplicates.sqlite
	mv /dev/shm/bioassayDatabaseNoDuplicates.sqlite $@

working/pubchemBioassay.sqlite: working/bioassayDatabaseNoDuplicates.sqlite 
	ln -s bioassayDatabaseNoDuplicates.sqlite $@ 

working/summarystats.txt: src/computeStats.R working/pubchemBioassay.sqlite working/bioassayMirror
	$^ $@

####################################################
# Optionally cluster targets and compute descriptors 
####################################################

# use kClust to cluster proteins by sequence
working/kClust: working/targets.fasta
	mkdir $@
	kClust -i $^ -d $@ -s 0.52 -M 16000MB

# compute atoms pairs for all compounds in parallel on mpi cluster 
working/ap.rda: src/make_apDatabase.sh src/computeAtomPairs.R working/pubchemCompoundMirror
	qsub $<

####################################################
# Optionally build EI Database of compounds
####################################################

# extract active CIDs and form SDF
working/activeCompounds.sdf: src/extractActives.R working/pubchemCompoundMirror working/bioassayDatabase.sqlite
	$^ $@

# split activeCompounds into small files to load in parallel
working/splitFolder: working/mayachemtools/bin/SplitSDFiles.pl working/activeCompounds.sdf
	mkdir -p $@
	$< ../activeCompounds.sdf --numcmpds 1000 -m Cmpds -w $@ 

# load compounds in parallel
working/eiDatabase: src/makeEiDatabaseParallel.R working/splitFolder 
	mkdir -p $@
	$^ $@ $(mpiCores)

# index EI database
working/indexedEiDatabase: src/indexEiDatabase.R working/eiDatabase 
	cp -R working/eiDatabase $@		
	$< $@ $(mpiCores)
