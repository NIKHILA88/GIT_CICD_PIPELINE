#!/bin/bash

index=$1
cd ../$index/conf
python ../../conf_validator/validate_confs.py inputs.conf props.conf > ../docs/validation.log
cat ../docs/validation.log | grep -n ERROR
echo "Conf files Validated."
