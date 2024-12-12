#!/bin/bash

for src in day-*.jai ; do
  echo
  echo "================================================"
  echo
  src=$(basename "$src")
  jai $src
  ./${src%%.*}
done
