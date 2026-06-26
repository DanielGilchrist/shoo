#!/bin/bash

SPEC_ARGS=""

for arg in "$@"; do
  SPEC_ARGS="$SPEC_ARGS $arg"
done

shards check || shards install && crystal spec --error-trace --progress $SPEC_ARGS
