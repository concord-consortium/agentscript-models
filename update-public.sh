#!/bin/bash

cp index.html public/index.html

for dir in "air-pollution" "air-pollution-aerial" "fracking" "global-climate" "lib" "solar-panel" "water"
do
	rsync -avz --exclude ".git" "$dir/" "public/$dir/"
done

for dir in "land-management"
do
	pushd "$dir"
	brunch build
	popd
	rsync -avz "$dir/public/" "public/$dir/"
done
