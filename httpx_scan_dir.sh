#!/bin/bash
##############################################
# httpx helper for multiple target file lists
# to avoid overwriting httpx output
##############################################

# try include escape quotes for HTTPX_ARGS if use double quotes
# ex: "\"upload|cmd\""
#     "'upload|cmd'"

HTTPX_ARGS_PATH="YOUR_TARGET_PATH"
HTTPX_ARGS_REGEX="YOUR_CUSTOM_REGEX"
TARGET_DIR="targets"
OUTPUT_DIR="output"
OUTPUT_PREFIX="shell"

if [ ! -d "${OUTPUT_DIR}" ];then
    mkdir -p "${OUTPUT_DIR}"
fi

for file in "${TARGET_DIR}"/*.txt;
do
    # Sometimes I delete some files while the process is running
    if [ -f "${file}" ];then
        outputfile=$(basename "${file}")
        outputpath="${OUTPUT_DIR}/${OUTPUT_PREFIX}-${outputfile}"
        echo "[*] Trying scan from list ${file}"
        echo "[*] Output file ${outputpath}"
        httpx -path "${HTTPX_ARGS_PATH}" -mr "${HTTPX_ARGS_REGEX}" -l "${file}" -o "${outputpath}" -stats -rstr 5242880 -nc
    else
        echo "[!] File ${file} not found"
    fi

done
