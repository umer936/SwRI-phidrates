#!/bin/sh
rsync -vaz --exclude 'tmp' --exclude '.svn' jmukherjee@guinan-new.space.swri.edu:/web/phidrates/ /web/RELEASE/phidrates
