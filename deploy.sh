#!/bin/sh

mv elm_dependencies.json elm_deps
cat elm_deps | tr  "\n" " " > elm_deps
sed -i 's/\"dependencies\": {.*}/\"dependencies\":{}/g' elm_deps
cp elm_deps elm_dependencies.json
./elm-get publish

#end
