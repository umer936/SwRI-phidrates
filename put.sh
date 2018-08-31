#!/bin/sh
rsync -vaz . --exclude 'tmp' --exclude '.svn' jmukherjee@guinan-new.space.swri.edu:/web/phidrates/
# rsync -vaz . --exclude '.svn' joey@guinan:/web/phidrates/
