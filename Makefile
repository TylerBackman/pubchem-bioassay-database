all: working/indexedBioassayDatabase.sqlite 

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
