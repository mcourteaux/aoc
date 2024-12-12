#!/bin/bash

echo "Compile all..."
for src in day-*.jai ; do
  jai -release $src &
done

wait

for src in day-*.jai ; do
  src=$(basename "$src")
  exe=${src%%.*}
  echo
  echo "====================== ${exe} =========================="
  echo
  ./${exe}
done
