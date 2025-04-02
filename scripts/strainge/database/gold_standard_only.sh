#!/bin/bash
source settings_global.sh
source strainge/settings.sh
set -e

strainge_gold_standard_listing="${STRAINGE_DB_DIR}/gold_standard_references.txt"
> "${strainge_gold_standard_listing}"

kmer_dir="${STRAINGE_DB_DIR}/gold_standard_kmers"
mkdir -p "${kmer_dir}"

for fasta_path in ${GOLD_STANDARD_DIR}/sequences/*.fasta.gz; do
  fasta_file=$(basename "${fasta_path}")
  asm_name="${fasta_file%.fasta.gz}"

  kmer_file="${kmer_dir}/${asm_name}.hdf5"
  if [ ! -f "${kmer_file}" ]; then
    echo "[!] Kmerizing: ${fasta_file}"
    straingst kmerize -o "${kmer_file}" "${fasta_path}"
  fi

  echo "[!] Adding ${kmer_file} to listing."
  echo "${kmer_file}" >> "${strainge_gold_standard_listing}"
done

echo "[!] Creating pan-genome kmer database files."
straingst createdb -o "${STRAINGE_GOLD_STANDARD_ONLY_DB}" -f "${strainge_gold_standard_listing}"
