all: working/indexedBioassayDatabase.sqlite 

clean:
	rm -rf working/*

working/bioassayMirror: scripts/mirrorBioassay.sh
	mkdir -p $@
	$^ $@
	
working/bioassayDatabase.sqlite: scripts/buildBioassayDatabase.R working/bioassayMirror
	$^ $@

working/indexedBioassayDatabase.sqlite: scripts/addDatabaseIndex.R working/bioassayDatabase.sqlite
	cp working/bioassayDatabase.sqlite $@
	scripts/addDatabaseIndex.R $@ 
