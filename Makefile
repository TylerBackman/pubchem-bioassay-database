all: working/pubchemBioassay.sqlite

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
	echo "SELECT DISTINCT target FROM targets WHERE target_type = \"protein\" AND targets NOT NULL;" | sqlite3 $< | xargs -I '{}' wget -O - "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id={}&rettype=fasta&retmode=text" >> $@

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

working/indexedBioassayDatabase.sqlite: scripts/addDatabaseIndex.R working/bioassayDatabaseWithDomains.sqlite 
	cp working/bioassayDatabaseWithDomains.sqlite $@
	$< $@ 

working/pubchemBioassay.sqlite: working/indexedBioassayDatabase.sqlite
	ln -s $< $@
