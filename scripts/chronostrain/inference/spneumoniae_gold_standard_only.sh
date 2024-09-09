#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
source chronostrain/inference/helpers.sh


out_subdir="chronostrain_spneumoniae_gold_standard_only"
db_dir="${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}"
database_json="${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_JSON}"
cluster_file="${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"



for i in $(seq 0 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}"
done
