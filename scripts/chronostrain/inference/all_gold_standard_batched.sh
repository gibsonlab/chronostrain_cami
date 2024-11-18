#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
source chronostrain/inference/helpers.sh


batch_size=5
for i in $(seq 0 ${batch_size} 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."

  # ====== Dense runs ========
  # E. coli
  out_subdir="chronostrain_ecoli_gold_standard_only"
  db_dir="${CHRONOSTRAIN_ECOLI_DB_DIR}"
  database_json="${CHRONOSTRAIN_ECOLI_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_ECOLI_GOLD_STANDARD_CLUSTERS}"
  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "dense" "${batch_size}"
#  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse" "${batch_size}"

  # E. coli (Paper version.)
  out_subdir="chronostrain_ecoli_paper_gold_standard_only"
  db_dir="${CHRONOSTRAIN_ECOLI_PAPER_DB_DIR}"
  database_json="${CHRONOSTRAIN_ECOLI_PAPER_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_ECOLI_PAPER_GOLD_STANDARD_CLUSTERS}"
  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "dense" "${batch_size}"
#  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse" "${batch_size}"

  # S. aureus
  out_subdir="chronostrain_saureus_gold_standard_only"
  db_dir="${CHRONOSTRAIN_SAUREUS_DB_DIR}"
  database_json="${CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_CLUSTERS}"
  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "dense" "${batch_size}"
#  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse" "${batch_size}"

  # S. pneumoniae
  out_subdir="chronostrain_spneumoniae_gold_standard_only"
  db_dir="${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}"
  database_json="${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"
  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "dense" "${batch_size}"
#  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse" "${batch_size}"

  # K. pneumoniae
  out_subdir="chronostrain_kpneumoniae_gold_standard_only"
  db_dir="${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}"
  database_json="${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"
  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "dense" "${batch_size}"
#  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse" "${batch_size}"

  # E. faecium
  out_subdir="chronostrain_efaecium_gold_standard_only"
  db_dir="${CHRONOSTRAIN_EFAECIUM_DB_DIR}"
  database_json="${CHRONOSTRAIN_EFAECIUM_GOLD_STANDARD_JSON}"
  cluster_file="${CHRONOSTRAIN_EFAECIUM_GOLD_STANDARD_CLUSTERS}"
  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "dense" "${batch_size}"
#  pipeline_multi_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse" "${batch_size}"
done

