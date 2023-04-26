#!/bin/bash

manifests_path="$1"
excluded_file="$2"

for file in $(find "$manifests_path" -type f -name "*.yaml" ! -path "$excluded_file" ); do
  kubectl apply -f "$file"
done
