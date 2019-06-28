#!/bin/sh

cd ..
mkdocs build --clean
cd site
git status
git add .
git commit -m 'Updated Docs'
git push