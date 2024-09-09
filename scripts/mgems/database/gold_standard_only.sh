#!/bin/bash
source settings_global.sh
source mgems/settings.sh


mkdir -p "${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}"
cd "${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}" || exit 1
echo "Working in ${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}"


# Extract the list of fasta file paths.
# sed | cut: skip the first line (header) and extract sixth column (fasta path).
sed '1d' "${GOLD_STANDARD_INDEX}" | cut -f6 > themisto_ref_paths.txt
n_genomes=$(wc -l themisto_ref_paths.txt | awk '{ print $1 }')
if [ $n_genomes -ne $MGEMS_GOLD_STANDARD_ONLY_N_COLORS ]; then
  echo "# of gold-standard genomes found (${n_genomes}) does not match the expected value (${MGEMS_GOLD_STANDARD_ONLY_N_COLORS})"
  exit 1
fi


# Build themisto index.
mkdir __tmp
themisto build -k 31 -i themisto_ref_paths.txt -o "${MGEMS_GOLD_STANDARD_ONLY_REF_INDEX}" --temp-dir __tmp
rm -rf __tmp


# Create mSWEEP aux file (list of cluster IDs --- one per gold standard. Not running poppunk here)

> "${MGEMS_GOLD_STANDARD_ONLY_REF_CLUSTER}"
for (( i=0; i<${n_genomes}; i+=1 )); do
    echo "$i" >> "${MGEMS_GOLD_STANDARD_ONLY_REF_CLUSTER}"
done
