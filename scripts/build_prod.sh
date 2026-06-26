#!/bin/bash

# This script assumes you're running it from the root of the project
# i.e. ./scripts/build_prod.sh

shards check || shards install \
  && mkdir -p bin \
  && crystal build src/main.cr --release --no-debug --progress --stats -o bin/shoo \
  && echo \
  && printf "\e[32mSuccess:\e[0m compiled release binary to $(pwd)/bin/shoo\n"
