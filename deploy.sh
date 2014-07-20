#!/bin/sh

elm-doc Graphics/ObjTypes.elm Graphics/ObjParser.elm

echo "starting deploy"
cat elm_dependencies.json
echo "done move"
cat elm_dependencies.json | tr  "\n" " " > elm_deps
echo "removed newlines"
cat elm_deps
sed -i 's/\"dependencies\": {[^}]*}/\"dependencies\":{}/g' elm_deps
echo "replaced deps"
cat elm_deps
rm elm_dependencies.json
cp elm_deps elm_dependencies.json
echo "copied file"
cat elm_dependencies.json
./elm-get publish
echo "did publish"

#end
