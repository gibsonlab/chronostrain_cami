#!/bin/bash
source settings_global.sh
source strainge/settings.sh
set -e

strainge_mut_only_listing="${STRAINGE_DB_DIR}/mut_only_references.txt"
> "${strainge_mut_only_listing}"

# ========== Kmerize mutated gold-standard genomes.
mut_kmer_dir="${STRAINGE_DB_DIR}/mut_kmers"
mkdir -p "${mut_kmer_dir}"
for fasta_path in ${DATA_DIR}/mutated_gold_standard/seed_12345/genomes/*.fasta.gz; do
  fasta_file=$(basename "${fasta_path}")
  asm_name="${fasta_file%.fasta.gz}"

  kmer_file="${mut_kmer_dir}/${asm_name}_Mut.hdf5"
  if [ ! -f "${kmer_file}" ]; then
    echo "[!] Kmerizing: ${fasta_file}"
    straingst kmerize -o "${kmer_file}" "${fasta_path}"
  fi

  echo "[!] Adding ${kmer_file} to listing."
  echo "${kmer_file}" >> "${strainge_mut_only_listing}"
done

echo "[!] Creating pan-genome kmer database files."
straingst createdb -o "${STRAINGE_MUT_ONLY_DB}" -f "${strainge_mut_only_listing}"
