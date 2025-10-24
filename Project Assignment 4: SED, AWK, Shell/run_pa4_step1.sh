#!/bin/bash

set -euo pipefail

INPUT_FILE="${1:-}"
OUTPUT_DIR="out"
LOG_DIR="logs"

usage() {
    echo "Usage: $0 <INPUT_FILE>"
    echo "Example: $0 data/samples/Spotify_Filtered_1k.csv"
    exit 1
}

if [[ -z "${INPUT_FILE}" ]]; then
    echo "Error: No input file provided"
    usage
fi

if [[ ! -f "${INPUT_FILE}" ]]; then
    echo "Error: Input file does not exist: ${INPUT_FILE}"
    exit 1
fi

if [[ ! -r "${INPUT_FILE}" ]]; then
    echo "Error: Input file is not readable: ${INPUT_FILE}"
    exit 1
fi

chmod -R g+rX "$(dirname "${INPUT_FILE}")" 2>/dev/null || true

mkdir -p "${OUTPUT_DIR}" "${LOG_DIR}"

echo "Starting data cleaning and normalization..."

# SED cleaning pipeline:
# 1. Remove BOM (Byte Order Mark) - UTF-8 BOM is 3 bytes: 357 273 277
# 2. Trim leading/trailing whitespace
# 3. Collapse multiple spaces to single space
# 4. Remove carriage returns (\r)
# 5. Normalize quotes and punctuation
# 6. Handle empty fields consistently
# 7. Standardize delimiter formatting

sed -E \
    -e '1s/^\xEF\xBB\xBF//' \
    -e 's/^[[:space:]]+|[[:space:]]+$//g' \
    -e 's/[[:space:]]+/ /g' \
    -e 's/\r//g' \
    -e 's/""//g' \
    -e 's/^"|"$//g' \
    -e 's/,[[:space:]]*$/,/g' \
    "${INPUT_FILE}" > "${OUTPUT_DIR}/cleaned_data.csv"

echo "Generating data quality samples..."
head -n 10 "${INPUT_FILE}" > "${OUTPUT_DIR}/before_sample.txt"
head -n 10 "${OUTPUT_DIR}/cleaned_data.csv" > "${OUTPUT_DIR}/after_sample.txt"

original_lines=$(wc -l < "${INPUT_FILE}")
cleaned_lines=$(wc -l < "${OUTPUT_DIR}/cleaned_data.csv")

echo "Data cleaning completed:"
echo "  Original lines: ${original_lines}"
echo "  Cleaned lines: ${cleaned_lines}"
echo "  Output saved to: ${OUTPUT_DIR}/cleaned_data.csv"
echo "  Samples saved to: ${OUTPUT_DIR}/before_sample.txt, ${OUTPUT_DIR}/after_sample.txt"

if [[ "${original_lines}" -ne "${cleaned_lines}" ]]; then
    echo "Warning: Line count changed during cleaning"
    echo "  This may indicate data quality issues"
fi

echo "Step 1 completed successfully!"
