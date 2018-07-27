#!/bin/sh
rsync -vaz . --exclude '.svn' jmukherjee@guinan-new.space.swri.edu:/web/phidrates/
