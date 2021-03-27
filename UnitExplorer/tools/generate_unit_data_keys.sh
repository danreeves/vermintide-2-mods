#!/bin/bash

rg "Unit.[sg]et_data\(.+\)" /mnt/c/dev/vmb/Vermintide-2-Source-Code --only-matching --no-filename --no-line-number --color never | awk NF
