#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
source chronostrain/inference/helpers.sh



for i in $(seq 0 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."

  # ====== Dense runs ========
  # E. coli
  out_subdir="chronostrain_ecoli_mut_only"
  db_dir="${CHRONOSTRAIN_ECOLI_DB_DIR}"
  database_json="${CHRONOSTRAIN_ECOLI_MUT_ONLY_JSON}"
  cluster_file="${CHRONOSTRAIN_ECOLI_MUT_ONLY_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"

  # E. coli (Paper version.)
  out_subdir="chronostrain_ecoli_paper_mut_only"
  db_dir="${CHRONOSTRAIN_ECOLI_PAPER_DB_DIR}"
  database_json="${CHRONOSTRAIN_ECOLI_PAPER_MUT_ONLY_JSON}"
  cluster_file="${CHRONOSTRAIN_ECOLI_PAPER_MUT_ONLY_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"

  # S. aureus
  out_subdir="chronostrain_saureus_mut_only"
  db_dir="${CHRONOSTRAIN_SAUREUS_DB_DIR}"
  database_json="${CHRONOSTRAIN_SAUREUS_MUT_ONLY_JSON}"
  cluster_file="${CHRONOSTRAIN_SAUREUS_MUT_ONLY_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"

  # S. pneumoniae
  out_subdir="chronostrain_spneumoniae_mut_only"
  db_dir="${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}"
  database_json="${CHRONOSTRAIN_SPNEUMONIAE_MUT_ONLY_JSON}"
  cluster_file="${CHRONOSTRAIN_SPNEUMONIAE_MUT_ONLY_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"

  # K. pneumoniae
  out_subdir="chronostrain_kpneumoniae_mut_only"
  db_dir="${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}"
  database_json="${CHRONOSTRAIN_KPNEUMONIAE_MUT_ONLY_JSON}"
  cluster_file="${CHRONOSTRAIN_KPNEUMONIAE_MUT_ONLY_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"

  # E. faecium
  out_subdir="chronostrain_efaecium_mut_only"
  db_dir="${CHRONOSTRAIN_EFAECIUM_DB_DIR}"
  database_json="${CHRONOSTRAIN_EFAECIUM_MUT_ONLY_JSON}"
  cluster_file="${CHRONOSTRAIN_EFAECIUM_MUT_ONLY_CLUSTERS}"
  pipeline_single_sample "${i}" "${out_subdir}" "${db_dir}" "${database_json}" "${cluster_file}" "sparse"
done

