#!/bin/bash
source settings_global.sh

mkdir -p "${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}"
cd "${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}" || exit 1


# Extract the list of fasta file paths.
# sed | cut: skip the first line (header) and extract sixth column.
sed '1d' "${GOLD_STANDARD_INDEX}" | cut -f6 > themisto_ref_paths.txt
themisto build -k 31 -i themisto_ref_paths.txt -o themisto_index --temp-dir __tmp
rm -rf __tmp
