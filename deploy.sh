#!/bin/sh

mv elm_dependencies.json elm_deps
echo "done move"
cat elm_deps | tr  "\n" " " > elm_deps
echo "removed newlines"
sed -i 's/\"dependencies\": {[^}]*}/\"dependencies\":{}/g' elm_deps
echo "replaced deps"
cp elm_deps elm_dependencies.json
echo "copied file"
cat elm_dependencies.json
./elm-get publish
echo "did publish"

#end
