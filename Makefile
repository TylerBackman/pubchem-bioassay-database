all: working/kClust working/pubchemBioassay.sqlite working/compounds.sqlite working/summarystats.txt

clean:
	rm -rf working/*

working/bioassayMirror: src/mirrorBioassay.sh
	mkdir -p $@
	$^ $@
	
working/bioassayDatabase.sqlite: src/buildBioassayDatabase.R working/bioassayMirror
	$^ proteinsOnly $@

working/targets.fasta: working/bioassayDatabase.sqlite
	echo "SELECT DISTINCT target FROM targets WHERE target_type = \"protein\";" | sqlite3 $< | xargs -I '{}' wget -O - "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id={}&rettype=fasta&retmode=text" >> $@

working/Pfam-A.hmm:
	wget -O $@.gz ftp://ftp.sanger.ac.uk/pub/databases/Pfam/releases/Pfam27.0/Pfam-A.hmm.gz
	gunzip $@.gz
	hmmpress $@

working/domainsFromHmmscan: working/Pfam-A.hmm working/targets.fasta
	hmmscan --tblout working/domainsFromHmmscan --cpu 8 --noali $^

working/domainsFromHmmscanTwoCols: working/domainsFromHmmscan
	awk '{print $$2 " " $$3}' $^ > $@

working/bioassayDatabaseWithDomains.sqlite: src/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols working/bioassayDatabase.sqlite
	cp working/bioassayDatabase.sqlite $@
	src/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols $@

working/indexedBioassayDatabase.sqlite: working/bioassayDatabaseWithDomains.sqlite 
	cp $< $@
	echo "CREATE INDEX IF NOT EXISTS activity_cid ON activity (cid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS activity_aid ON activity (aid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS targets_aid ON targets (aid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS targets_target ON targets (target);" | sqlite3 $@

working/bioassayDatabaseWithSpecies.sqlite: src/annotateSpecies.R working/indexedBioassayDatabase.sqlite
	cp working/indexedBioassayDatabase.sqlite $@
	$< $@

working/pubchemBioassay.sqlite: working/bioassayDatabaseWithSpecies.sqlite 
	ln -s bioassayDatabaseWithSpecies.sqlite $@ 

working/compounds.sqlite: src/getCids.R working/bioassayDatabase.sqlite
	$^ $@

working/summarystats.txt: src/computeStats.R working/pubchemBioassay.sqlite
	$^ $@

# use kClust to cluster proteins by sequence
working/kClust: working/targets.fasta
	mkdir $@
	kClust -i $^ -d $@ -s 0.52 -M 16000MB

# download all of PubChem Compound
working/pubchemCompoundMirror:
	mkdir -p $@
	wget -r -nd ftp://ftp.ncbi.nlm.nih.gov/pubchem/Compound/CURRENT-Full/SDF/ -P $@

# compute atoms pairs for all compounds that participate in at least 10 assays

