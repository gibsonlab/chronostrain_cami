#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
source chronostrain/inference/helpers.sh



for i in $(seq 0 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."

  # ====== Dense runs ========
  # E. coli
  out_subdir="chronostrain_ecoli_gold_with_reference"
  db_dir="${CHRONOSTRAIN_ECOLI_DB_DIR}"
  database_json="${CHRONOSTRAIN_ECOLI_HYBRID_JSON}"
  cluster_file="${CHRONOSTRAIN_ECOLI_HYBRID_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"
done

