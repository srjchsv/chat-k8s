#!/bin/bash

FILE_PATH="$1"
OLD_VALUE="$2"
NEW_VALUE="$3"

sed -i "s/$OLD_VALUE/$NEW_VALUE/g" "$FILE_PATH"
