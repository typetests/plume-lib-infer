#!/bin/bash
ROOT=$TRAVIS_BUILD_DIR/..

# Fail the whole script if any command fails
set -e

## Build Checker Framework
(cd $ROOT && git clone https://github.com/typetools/checker-framework.git)
# This also builds annotation-tools and jsr308-langtools
(cd $ROOT/checker-framework/ && ./.travis-build-without-test.sh)
export CHECKERFRAMEWORK=$ROOT/checker-framework

## Obtain plume-lib
(cd $ROOT && git clone https://github.com/mernst/plume-lib.git)

cd $ROOT/plume-lib

# Remove annotations in comments
(cd java && find \( -name '*.java' -o -name '*.jpp' \) -exec perl -i -00pe's/\/\*@[A-Z][^*]*?[a-z)]\*\/[ \n]*//sg;' {} +)
## Retain import statements in comments, to reduce the size of the diffs
# # Remove import statements in comments
# (cd java && find \( -name '*.java' -o -name '*.jpp' \) -exec perl -i -00pe's/\/\*>>>.*?\*\/\n*//sg;' {} +)

make jar
$CHECKERFRAMEWORK/checker/bin/infer-and-annotate.sh \
    "nullness,interning,formatter,signature,lock" java/plume.jar:java/lib/junit-4.12.jar \
    -AprintErrorStack \
    `find java/src/plume/ -name "*.java"`

git diff
