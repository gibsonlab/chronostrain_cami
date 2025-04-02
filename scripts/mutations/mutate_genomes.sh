#!/bin/bash
source settings_global.sh


mutation_rate=0.002
seed=12345
mutated_dir=${DATA_DIR}/mutated_gold_standard/seed_${seed}

echo "[!] Target mutation dir: ${mutated_dir}"
mkdir -p "${mutated_dir}"
python mutations/mutate_genomes.py \
  -i "${GOLD_STANDARD_INDEX}" \
  -o "${mutated_dir}/index.tsv" \
  -m "${mutation_rate}" \
  -d "${mutated_dir}/genomes" \
  -s "${seed}"
