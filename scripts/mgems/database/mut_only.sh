#!/bin/bash
set -e
source settings_global.sh
source mgems/settings.sh
# Creates a themisto index using all gold-standard genomes.

mkdir -p "${MGEMS_MUT_ONLY_REF_DIR}"
cd "${MGEMS_MUT_ONLY_REF_DIR}" || exit 1
echo "Working in ${MGEMS_MUT_ONLY_REF_DIR}"


# Create a table translating msweep cluster index to gold-standard ID.
echo -e "ID\tFasta\tCluster" > ref_info.tsv
sed '1d' "${DATA_DIR}/mutated_gold_standard/seed_12345/index.tsv" | cut -f4,6 | awk -v offset="${nr_lines}" -v OFS='\t' '{print $1,$2,NR-1}' >> ref_info.tsv

# Extract the list of fasta file paths.
# sed | cut: skip the first line (header) and extract sixth column (fasta path).
sed '1d' ref_info.tsv | cut -f2 > themisto_ref_paths.txt


# Build themisto index.
mkdir __tmp
themisto build -k 31 -i themisto_ref_paths.txt -o "${MGEMS_MUT_ONLY_REF_INDEX}" --temp-dir __tmp
rm -rf __tmp


# Create mSWEEP aux file (list of cluster IDs --- one per gold standard. Not running poppunk here)
sed '1d' ref_info.tsv | cut -f3 > "${MGEMS_MUT_ONLY_REF_CLUSTER}"



