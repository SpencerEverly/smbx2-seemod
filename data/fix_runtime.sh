#!/bin/bash

# Adding system attribute for folders to allow them has icons
attrib +s graphics
for x in \
	block effect player costumes bowser klonoa level link luigi mario megaman \
	ninjabomberman npc particles path peach rosalina samus scene snake tile \
	toad ultimaterinka unclebroadsword wario zelda
do
	attrib +s "graphics/$x"
done
attrib +s scripts
attrib +s worlds

# Convert LF's into CRLF's
for x in \
	txt lua frag vert shader lvl wld
do
	find . -type f -name "*.$x" -exec unix2dos {} \;
done
git config core.autocrlf true

echo
echo "Everything has been done!"
