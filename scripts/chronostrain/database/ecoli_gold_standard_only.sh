#!/bin/bash
source settings_global.sh

# Required Files
CHRONOSTRAIN_DB_DIR="${DATA_DIR}/inference/databases/chronostrain/ecoli"

MARKER_SEED_INDEX="${MISC_DATA_DIR}/chronostrain_seeds/ecoli/marker_seed_index.tsv"
if [ ! -f ${MARKER_SEED_INDEX} ]; then
  echo "Extracting marker seeds from archive."
  tar -xvzf "${MISC_DATA_DIR}/chronostrain_seeds.tar.gz" -C "${MISC_DATA_DIR}"
fi

# Reference Genome/Isolate BLAST database
BLAST_DB_DIR="${CHRONOSTRAIN_DB_DIR}/blast_db"  # The location of the Blast DB that you wish to create using RefSeq indices (they will be downloaded by this notebook).
BLAST_DB_NAME="CAMI_Strain_Madness_Gold"  # Blast DB to create.

# chronostrain-specific settings
NUM_CORES=8  # number of cores to use (e.g. for blastn)
MARKER_MIN_PCT_IDTY=75  # accept BLAST hits as markers above this threshold

# Some checks.
if [ ! -f "${GOLD_STANDARD_INDEX}" ]; then echo "Couldn't find ${GOLD_STANDARD_INDEX}"; fi
if [ ! -f "${MARKER_SEED_INDEX}" ]; then echo "Couldn't find ${MARKER_SEED_INDEX}"; fi
mkdir -p "${CHRONOSTRAIN_DB_DIR}"
mkdir -p "${BLAST_DB_DIR}"
echo "All necessary files accounted for."

# Construct the gold-standard-only DB.
env \
    JAX_PLATFORM_NAME=cpu \
    CHRONOSTRAIN_DB_DIR="${CHRONOSTRAIN_DB_DIR}" \
    CHRONOSTRAIN_LOG_INI=logging.ini \
    chronostrain -c chronostrain.ini \
      make-db \
      -m "$MARKER_SEED_INDEX" \
      -r "$GOLD_STANDARD_INDEX" \
      -b $BLAST_DB_NAME -bd "$BLAST_DB_DIR" \
      --min-pct-idty "$MARKER_MIN_PCT_IDTY" \
      -o "$CHRONOSTRAIN_GOLD_STANDARD_JSON" \
      --threads "$NUM_CORES"


# Now add the gold-standard to the cluster file.
# Extract from the JSON file all gold-standard genomes that made it into the database.
cat "$CHRONOSTRAIN_GOLD_STANDARD_JSON" | grep "genus" -B 3 -A 3 | grep "id" | sed -r 's/\s+"id":\s"(.*?)",/\1/' > "${CHRONOSTRAIN_GOLD_STANDARD_CLUSTERS}"

# Extract from the index file, printing only the 3rd column (awk), skipping the header line of the TSV (tail)
#awk 'BEGIN {FS="\t"} {print $3}' "${GOLD_STANDARD_INDEX}" | tail -n +2 > "${CHRONOSTRAIN_GOLD_STANDARD_CLUSTERS}"
