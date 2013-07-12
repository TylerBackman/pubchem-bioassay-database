all: working/pubchemBioassay.sqlite working/compounds.sqlite

clean:
	rm -rf working/*

working/bioassayMirror: scripts/mirrorBioassay.sh
	mkdir -p $@
	$^ $@
	
working/bioassayDatabase.sqlite: scripts/buildBioassayDatabase.R working/bioassayMirror
	$^ $@

working/bioassayDatabaseWithAssayDetails.sqlite: scripts/addAssayDetails.R working/bioassayMirror working/bioassayDatabase.sqlite
	cp working/bioassayDatabase.sqlite $@
	$< working/bioassayMirror $@

working/targets.fasta: working/bioassayDatabaseWithAssayDetails.sqlite
	echo "SELECT DISTINCT target FROM targets WHERE target_type = \"protein\";" | sqlite3 $< | xargs -I '{}' wget -O - "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id={}&rettype=fasta&retmode=text" >> $@

working/Pfam-A.hmm:
	wget -O $@.gz ftp://ftp.sanger.ac.uk/pub/databases/Pfam/releases/Pfam27.0/Pfam-A.hmm.gz
	gunzip $@.gz
	hmmpress $@

working/domainsFromHmmscan: working/Pfam-A.hmm working/targets.fasta
	hmmscan --tblout working/domainsFromHmmscan --cpu 8 --noali $^

working/domainsFromHmmscanTwoCols: working/domainsFromHmmscan
	awk '{print $$2 " " $$3}' $^ > $@

working/bioassayDatabaseWithDomains.sqlite: scripts/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols working/bioassayDatabaseWithAssayDetails.sqlite
	cp working/bioassayDatabaseWithAssayDetails.sqlite $@
	scripts/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols $@

working/indexedBioassayDatabase.sqlite: working/bioassayDatabaseWithDomains.sqlite 
	cp $< $@
	echo "CREATE INDEX IF NOT EXISTS activity_cid ON activity (cid);" | sqlite3 $@
	echo "CREATE INDEX IF NOT EXISTS targets_aid ON targets (aid);" | sqlite3 $@

working/pubchemBioassay.sqlite: working/indexedBioassayDatabase.sqlite
	ln -s $< $@

working/compounds.sqlite: scripts/getCids.R working/pubchemBioassay.sqlite
	$^ $@
