#!/bin/bash
source settings_global.sh
source strainge/settings.sh
set -e

strainge_gold_with_mut_listing="${STRAINGE_DB_DIR}/gold_with_mutation_references.txt"
> "${strainge_gold_with_mut_listing}"

# ========== Kmerize gold-standard genomes.
gold_kmer_dir="${STRAINGE_DB_DIR}/gold_standard_kmers"
mkdir -p "${gold_kmer_dir}"
for fasta_path in ${GOLD_STANDARD_DIR}/sequences/*.fasta.gz; do
  fasta_file=$(basename "${fasta_path}")
  asm_name="${fasta_file%.fasta.gz}"

  kmer_file="${gold_kmer_dir}/${asm_name}.hdf5"
  if [ ! -f "${kmer_file}" ]; then
    echo "[!] Kmerizing: ${fasta_file}"
    straingst kmerize -o "${kmer_file}" "${fasta_path}"
  fi

  echo "[!] Adding ${kmer_file} to listing."
  echo "${kmer_file}" >> "${strainge_gold_with_mut_listing}"
done

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
  echo "${kmer_file}" >> "${strainge_gold_with_mut_listing}"
done

echo "[!] Creating pan-genome kmer database files."
straingst createdb -o "${STRAINGE_GOLD_WITH_MUT_DB}" -f "${strainge_gold_with_mut_listing}"
