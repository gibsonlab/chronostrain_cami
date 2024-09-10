#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
source chronostrain/inference/helpers.sh


out_subdir="chronostrain_kpneumoniae_gold_standard_only"
db_dir="${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}"
database_json="${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_JSON}"
cluster_file="${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"



for i in $(seq 0 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}"
done
