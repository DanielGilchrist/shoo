#!/bin/bash

# This script assumes you're running it from the root of the project
# i.e. ./scripts/build_prod.sh

shards check || shards install && crystal build src/shoo.cr --release --no-debug --progress --stats \
  && mkdir -p bin \
  && mv shoo bin/shoo \
  && echo \
  && printf "\e[32mSuccess:\e[0m compiled release binary to $(pwd)/bin/shoo\n"
