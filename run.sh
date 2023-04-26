#!/bin/bash

for file in $(find . -type f -name "*.yaml" -o -name "*.yml") -not -path "./manifests/ingress/ingress.yaml"
do
  kubectl apply -f "$file"
done
