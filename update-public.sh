#!/bin/bash

cp index.html public/index.html
cp Gemfile public/Gemfile
cp s3_website.yml public/s3_website.yml
cp .travis.yml public/.travis.yml

for dir in "assets" "air-pollution-aerial" "fracking" "global-climate" "lib" "solar-panel" "water"
do
	rsync -avz --exclude ".git" "$dir/" "public/$dir/"
done

for dir in "air-pollution" "land-management"
do
	pushd "$dir"
	brunch build
	popd
	rsync -avz "$dir/public/" "public/$dir/"
done
