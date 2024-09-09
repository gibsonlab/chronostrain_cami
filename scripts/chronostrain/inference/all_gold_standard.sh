#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
source chronostrain/inference/helpers.sh



for i in $(seq 0 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."

  # E. coli
  out_subdir="chronostrain_ecoli_gold_standard_only"
  db_dir="${CHRONOSTRAIN_ECOLI_DB_DIR}"
  database_json="${CHRONOSTRAIN_ECOLI_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_ECOLI_GOLD_STANDARD_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}"

  # S. aureus
  out_subdir="chronostrain_saureus_gold_standard_only"
  db_dir="${CHRONOSTRAIN_SAUREUS_DB_DIR}"
  database_json="${CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}"

  # S. pneumoniae
  out_subdir="chronostrain_spneumoniae_gold_standard_only"
  db_dir="${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}"
  database_json="${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}"

  # K. pneumoniae
  out_subdir="chronostrain_kpneumoniae_gold_standard_only"
  db_dir="${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}"
  database_json="${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}"
done

