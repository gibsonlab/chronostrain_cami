#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
set -e

# Required Files

create_from_seeds() {
  taxa_name=$1
  db_dir=$2
  json_path=$3
  cluster_path=$4

  echo "[!] Starting database creation routine for ${taxa_name}."

  # Unpack marker seeds from tarball archive, if it hasn't already been.
  marker_seed_index="${MISC_DATA_DIR}/chronostrain_seeds/${taxa_name}/marker_seed_index.tsv"
  if [ ! -f "${marker_seed_index}" ]; then
    echo "[!] Extracting marker seeds from archive."
    tar -xvzf "${MISC_DATA_DIR}/chronostrain_seeds.tar.gz" -C "${MISC_DATA_DIR}"
  fi
  if [ ! -f "${marker_seed_index}" ]; then
    echo "[! Error] Archive did not contain marker seed index for taxa ${taxa_name}."
    exit 1
  fi

  # Reference Genome/Isolate BLAST database
  blast_db_dir="${db_dir}/blast_db"  # The location of the Blast DB that you wish to create using RefSeq indices (they will be downloaded by this notebook).
  blast_db_name="mutated_CAMI_Strain_Madness_Gold"  # Blast DB to create.

  # chronostrain-specific settings
  NUM_CORES=8  # number of cores to use (e.g. for blastn)
  MARKER_MIN_PCT_IDTY=75  # accept BLAST hits as markers above this threshold

  # Some checks.
  if [ ! -f "${GOLD_STANDARD_INDEX}" ]; then echo "Couldn't find ${GOLD_STANDARD_INDEX}"; fi
  if [ ! -f "${marker_seed_index}" ]; then echo "Couldn't find ${marker_seed_index}"; fi
  echo "target DB DIR: ${db_dir}"
  echo "target Blast DB DIR: ${blast_db_dir}"
  mkdir -p "${db_dir}"
  mkdir -p "${blast_db_dir}"
  echo "target JSON: ${json_path}"
  echo "[!] All necessary files accounted for. Invoking chronostrain make-db."

  # Construct the gold-standard-only DB.
  env \
      JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_DIR="${db_dir}" \
      CHRONOSTRAIN_LOG_INI=logging.ini \
      CHRONOSTRAIN_DB_JSON="${json_path}" \
      chronostrain make-db \
        -m "${marker_seed_index}" \
        -r "$GOLD_STANDARD_INDEX" \
        -r "${DATA_DIR}/mutated_gold_standard/seed_12345/index.tsv" \
        -b "${blast_db_name}" -bd "${blast_db_dir}" \
        --min-pct-idty "$MARKER_MIN_PCT_IDTY" \
        -o "${json_path}" \
        --threads "$NUM_CORES"


  # Now add the gold-standard to the cluster file.
  # Extract from the JSON file all gold-standard genomes that made it into the database.
  # (note: this is for chronostrain's -s option, which is optional but integrated into the shell scripts.)
  cat "${json_path}" | grep "genus" -B 3 -A 3 | grep "id" | sed -r 's/\s+"id":\s"(.*?)",/\1/' > "${cluster_path}"
}

create_from_seeds "Escherichia_coli" "${CHRONOSTRAIN_ECOLI_DB_DIR}" "${CHRONOSTRAIN_ECOLI_GOLD_MUT_JSON}" "${CHRONOSTRAIN_ECOLI_GOLD_MUT_CLUSTERS}"
create_from_seeds "Escherichia_coli_paper" "${CHRONOSTRAIN_ECOLI_PAPER_DB_DIR}" "${CHRONOSTRAIN_ECOLI_PAPER_GOLD_MUT_JSON}" "${CHRONOSTRAIN_ECOLI_PAPER_GOLD_MUT_CLUSTERS}"
create_from_seeds "Staphylococcus_aureus" "${CHRONOSTRAIN_SAUREUS_DB_DIR}" "${CHRONOSTRAIN_SAUREUS_GOLD_MUT_JSON}" "${CHRONOSTRAIN_SAUREUS_GOLD_MUT_CLUSTERS}"
create_from_seeds "Streptococcus_pneumoniae" "${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}" "${CHRONOSTRAIN_SPNEUMONIAE_GOLD_MUT_JSON}" "${CHRONOSTRAIN_SPNEUMONIAE_GOLD_MUT_CLUSTERS}"
create_from_seeds "Klebsiella_pneumoniae" "${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}" "${CHRONOSTRAIN_KPNEUMONIAE_GOLD_MUT_JSON}" "${CHRONOSTRAIN_KPNEUMONIAE_GOLD_MUT_CLUSTERS}"
create_from_seeds "Enterococcus_faecium" "${CHRONOSTRAIN_EFAECIUM_DB_DIR}" "${CHRONOSTRAIN_EFAECIUM_GOLD_MUT_JSON}" "${CHRONOSTRAIN_EFAECIUM_GOLD_MUT_CLUSTERS}"

