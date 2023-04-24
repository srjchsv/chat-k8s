#!/bin/bash

for file in $(find . -type f -name "*.yaml" -o -name "*.yml")
do
  kubectl apply -f "$file"
done
