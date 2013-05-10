all: working/bioassayDatabaseWithDomains.sqlite

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

working/indexedBioassayDatabase.sqlite: scripts/addDatabaseIndex.R working/bioassayDatabaseWithAssayDetails.sqlite
	cp working/bioassayDatabaseWithAssayDetails.sqlite $@
	$< $@ 

working/targets.fasta: working/indexedBioassayDatabase.sqlite
	echo "SELECT DISTINCT targets FROM assays WHERE target_type = \"protein\" AND targets NOT NULL;" | sqlite3 $< | xargs -I '{}' wget -O - "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id={}&rettype=fasta&retmode=text" >> $@

working/Pfam-A.hmm:
	wget -O $@.gz ftp://ftp.sanger.ac.uk/pub/databases/Pfam/releases/Pfam27.0/Pfam-A.hmm.gz
	gunzip $@.gz
	hmmpress $@

working/domainsFromHmmscanTwoCols: working/Pfam-A.hmm working/targets.fasta
	hmmscan --tblout working/domainsFromHmmscan --cpu 8 --noali $^
	awk '{print $2 \" \" $3}' working/domainsFromHmmscan > $@ 

working/bioassayDatabaseWithDomains.sqlite: scripts/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols working/indexedBioassayDatabase.sqlite
	cp working/indexedBioassayDatabase.sqlite $@
	scripts/loadDomainData.R working/targets.fasta working/domainsFromHmmscanTwoCols $@
