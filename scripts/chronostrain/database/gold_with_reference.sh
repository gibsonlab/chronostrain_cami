#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
set -e

# Required Files

create_from_seeds() {
  db_name=$1
  genus=$2
  species=$3
  db_dir=$4
  json_path=$5
  cluster_path=$6
  reference_index=$7

  echo "[!] Starting database creation routine for ${db_name}."

  # Unpack marker seeds from tarball archive, if it hasn't already been.
  # marker_seed_index="${MISC_DATA_DIR}/chronostrain_seeds/${db_name}/marker_seed_index.tsv"  # index containing all marker seeds including MLST.
  marker_seed_index="${MISC_DATA_DIR}/chronostrain_seeds/${db_name}/metaphlan_seed_index.tsv"  # Only use metaphlan seeds here, since we're only cataloguing the target species.

  if [ ! -f "${marker_seed_index}" ]; then
    echo "[!] Extracting marker seeds from archive."
    tar -xvzf "${MISC_DATA_DIR}/chronostrain_seeds.tar.gz" -C "${MISC_DATA_DIR}"
  fi
  if [ ! -f "${marker_seed_index}" ]; then
    echo "[! Error] Archive did not contain marker seed index for taxa ${db_name}."
    exit 1
  fi

  # Reference Genome/Isolate BLAST database
  blast_db_dir="${db_dir}/blast_db"  # The location of the Blast DB that you wish to create using RefSeq indices (they will be downloaded by this notebook).
  blast_db_name="CAMI_Strain_Madness_Gold_Plus_Reference"  # Blast DB to create.

  # chronostrain-specific settings
  NUM_CORES=8  # number of cores to use (e.g. for blastn)
  MARKER_MIN_PCT_IDTY=75  # accept BLAST hits as markers above this threshold

  # Some checks.
  if [ ! -f "${GOLD_STANDARD_INDEX}" ]; then echo "Couldn't find ${GOLD_STANDARD_INDEX}"; fi
  if [ ! -f "${marker_seed_index}" ]; then echo "Couldn't find ${marker_seed_index}"; fi
  if [ ! -f "${reference_index}" ]; then echo "Couldn't find ${reference_index}"; fi
  mkdir -p "${db_dir}"
  mkdir -p "${blast_db_dir}"

  # Filter gold standard into species-specific index.
  gold_standard_filtered_index=${db_dir}/${db_name}_gold_standard.tsv
  head "${GOLD_STANDARD_INDEX}" -n 1 > $gold_standard_filtered_index
  cat "${GOLD_STANDARD_INDEX}" | grep "^${genus}\s" | grep "\s${species}\s" >> $gold_standard_filtered_index

  # Construct the gold-standard-only DB.
  echo "[!] All necessary files accounted for. Invoking chronostrain make-db."
  env \
      JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_DIR="${db_dir}" \
      CHRONOSTRAIN_LOG_INI=logging.ini \
      CHRONOSTRAIN_DB_JSON="${json_path}" \
      chronostrain make-db \
        -m "${marker_seed_index}" \
        -r "$GOLD_STANDARD_INDEX" \
        -r "$reference_index" \
        -b "${blast_db_name}" -bd "${blast_db_dir}" \
        --min-pct-idty "$MARKER_MIN_PCT_IDTY" \
        -o "${json_path}" \
        --threads "$NUM_CORES"


  # Now add the gold-standard to the cluster file.
  # Extract from the JSON file all gold-standard genomes that made it into the database.
  # (note: this is for chronostrain's -s option, which is optional but integrated into the shell scripts.)
  env \
      JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_DIR="${db_dir}" \
      CHRONOSTRAIN_LOG_INI=logging.ini \
      CHRONOSTRAIN_DB_JSON="${json_path}" \
      chronostrain cluster-db \
        -i "${json_path}" \
        -o "${cluster_path}" \
        --ident-threshold 0.999999999999

  # Simple concatenation from JSON file.
#  cat "${json_path}" | grep "genus" -B 3 -A 3 | grep "id" | sed -r 's/\s+"id":\s"(.*?)",/\1/' > "${cluster_path}"
}

create_from_seeds "Escherichia_coli_paper" "Escherichia" "coli" "${CHRONOSTRAIN_ECOLI_PAPER_DB_DIR}" "${CHRONOSTRAIN_ECOLI_PAPER_GOLD_STANDARD_JSON}" "${CHRONOSTRAIN_ECOLI_PAPER_GOLD_STANDARD_CLUSTERS}"
create_from_seeds "Escherichia_coli" "Escherichia" "coli" "${CHRONOSTRAIN_ECOLI_DB_DIR}" "${CHRONOSTRAIN_ECOLI_HYBRID_JSON}" "${CHRONOSTRAIN_ECOLI_HYBRID_CLUSTERS}" "${ECOLI_NCBI_INDEX}"
create_from_seeds "Staphylococcus_aureus" "Staphylococcus" "aureus" "${CHRONOSTRAIN_SAUREUS_DB_DIR}" "${CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_JSON}" "${CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_CLUSTERS}"
create_from_seeds "Streptococcus_pneumoniae" "Streptococcus" "pneumoniae" "${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}" "${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_JSON}" "${CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"
create_from_seeds "Klebsiella_pneumoniae" "Klebsiella" "pneumoniae" "${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}" "${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_JSON}" "${CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_CLUSTERS}"
create_from_seeds "Enterococcus_faecium" "Enterococcus" "faecium" "${CHRONOSTRAIN_EFAECIUM_DB_DIR}" "${CHRONOSTRAIN_EFAECIUM_GOLD_STANDARD_JSON}" "${CHRONOSTRAIN_EFAECIUM_GOLD_STANDARD_CLUSTERS}"

