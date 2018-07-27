#!/bin/sh
rsync -vaz --exclude '.svn' joey@guinan.space.swri.edu:/web/phidrates/ /web/RELEASE/phidrates
