#!/bin/bash
source settings_global.sh
# Run this script to download (and index!!) the gold-standard genomes.

# Step 1. Download
if [ ! -f "${GOLD_STANDARD_GZ}" ]; then
  wget "https://frl.publisso.de/data/frl:6425521/strain/strmgCAMI2_genomes.tar.gz" -O "${GOLD_STANDARD_GZ}"
fi


# Step 2. Extract
seq_dir=${GOLD_STANDARD_DIR}/sequences
mkdir -p "${seq_dir}"
tar -xvzf "${GOLD_STANDARD_GZ}" -C "${seq_dir}"


# Step 3. Build the index.
index_file=${GOLD_STANDARD_DIR}/index.tsv

echo -e "Genus\tSpecies\tStrain\tAccession\tAssembly\tSeqPath\tChromosomeLen\tGFF" > "${index_file}"
for fasta_path in ${seq_dir}/short_read/source_genomes/*.fasta; do
  # Build the index, row by row.
  fasta_file=$(basename ${fasta_path})
  asm_name="${fasta_file%%.*}"
  mv "${fasta_path}" "${seq_dir}"
  echo -e "Unknown\tUnknown\t${asm_name}\t${asm_name}\t${asm_name}\t${seq_dir}/${fasta_file}\t0\t" >> "${index_file}"
done

# Clean up.
rm -rf "${seq_dir}/short_read"
