all: working/bioassayDatabase.sqlite

clean:
	rm -rf working/*

working:
	mkdir $@

working/bioassayMirror: scripts/mirrorBioassay.sh working
	mkdir $@
	$^/bioassayMirror
	
working/bioassayDatabase.sqlite: scripts/buildBioassayDatabase.R working/bioassayMirror
	$^ $@
