all: working/indexedBioassayDatabase.sqlite 

clean:
	rm -rf working/*

working/bioassayMirror: scripts/mirrorBioassay.sh
	mkdir -p $@
	$^ $@
	
working/bioassayDatabase.sqlite: scripts/buildBioassayDatabase.R working/bioassayMirror
	$^ $@

working/bioassayDatabaseWithAssayDetails.sqlite: scripts/addAssayDetails.R working/bioassayMirror scripts/parseBioassayXML.R working/bioassayDatabase.sqlite
	cp working/bioassayDatabase.sqlite $@
	$< working/bioassayMirror scripts/parseBioassayXML.R $@

working/indexedBioassayDatabase.sqlite: scripts/addDatabaseIndex.R working/bioassayDatabaseWithAssayDetails.sqlite
	cp working/bioassayDatabaseWithAssayDetails.sqlite $@
	$< $@ 
