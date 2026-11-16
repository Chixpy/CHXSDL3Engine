#!/bin/bash

pushd "$(dirname "$0")" > /dev/null || exit

mkdir -p bin
mkdir -p lib

fpc @fpcfg.cfg "$@"
ERRCOMP=$?

popd > /dev/null || exit

exit $ERRCOMP
