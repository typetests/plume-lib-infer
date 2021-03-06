#!/bin/bash
ROOT="$( cd "$(dirname "$0")"/.. ; pwd -P )"

# Fail the whole script if any command fails
set -e

## Build Checker Framework
(cd $ROOT && git clone https://github.com/typetools/checker-framework.git) || (cd $ROOT && git clone https://github.com/typetools/checker-framework.git)
# This also builds annotation-tools
(cd $ROOT/checker-framework/ && ./.travis-build-without-test.sh downloadjdk)
export CHECKERFRAMEWORK=$ROOT/checker-framework

## Obtain plume-lib
# rm command is handy when running this script by hand
rm -rf $ROOT/plume-lib
(cd $ROOT && git clone https://github.com/mernst/plume-lib.git) || (cd $ROOT && git clone https://github.com/mernst/plume-lib.git)

cd $ROOT/plume-lib

# Remove annotations in comments
# TODO: What other annotations to retain? @RequiresNonNull, others?
(cd java && find \( -name '*.java' -o -name '*.jpp' \) -exec perl -i -00pe's/\/\*(?!\@Pure|\@SideEffectFree|\@Deterministic)\@[A-Z][^*]*?[a-z)]\*\/[ \n]*//sg;' {} +)
## Retain import statements in comments, to reduce the size of the diffs
# # Remove import statements in comments
# (cd java && find \( -name '*.java' -o -name '*.jpp' \) -exec perl -i -00pe's/\/\*>>>.*?\*\/\n*//sg;' {} +)

make jar

# TODO: infer regex annotations, once whole-program inference works for regex
time $CHECKERFRAMEWORK/checker/bin/infer-and-annotate.sh \
    "nullness,interning,formatter,signature,lock" java/plume.jar:java/lib/junit-4.12.jar \
    -AprintErrorStack \
    `find java/src/plume/ -name "*.java"`

## TODO: use interdiff to compare this to a goal set of diffs.
## The goal set needs to be checked into this repository.
git diff
