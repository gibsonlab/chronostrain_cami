#!/bin/bash
source settings_global.sh

# Required Files
CHRONOSTRAIN_DB_DIR="${DATA_DIR}/inference/databases/chronostrain/ecoli"
GOLD_STANDARD_INDEX="${DATA_DIR}/gold_standard_genomes/index.tsv"
MARKER_SEED_INDEX=../../../data/seeds/ecoli/marker_seed_index.tsv

# Reference Genome/Isolate BLAST database
BLAST_DB_DIR=CHRONOSTRAIN_DB_DIR / "blast_db"  # The location of the Blast DB that you wish to create using RefSeq indices (they will be downloaded by this notebook).
BLAST_DB_NAME="CAMI_Strain_Madness_Gold"  # Blast DB to create.

# chronostrain-specific settings
NUM_CORES=8  # number of cores to use (e.g. for blastn)
MARKER_MIN_PCT_IDTY=75  # accept BLAST hits as markers above this threshold
CHRONOSTRAIN_TARGET_JSON="${CHRONOSTRAIN_DB_DIR}/gold_standard_only.json"

# Some checks.
if [ ! -f ${GOLD_STANDARD_INDEX} ]; then echo "Couldn't find ${GOLD_STANDARD_INDEX}"; fi
if [ ! -f ${MARKER_SEED_INDEX} ]; then echo "Couldn't find ${MARKER_SEED_INDEX}"; fi
mkdir -p "${CHRONOSTRAIN_DB_DIR}"
mkdir -p "${BLAST_DB_DIR}"
echo "All necessary files accounted for."

# Construct the gold-standard-only DB.
env \
    JAX_PLATFORM_NAME=cpu \
    CHRONOSTRAIN_DB_DIR={CHRONOSTRAIN_DB_DIR} \
    CHRONOSTRAIN_LOG_INI=logging.ini \
    chronostrain -c chronostrain.ini \
      make-db \
      -m $MARKER_SEED_INDEX \
      -r $GOLD_STANDARD_INDEX \
      -b $BLAST_DB_NAME -bd $BLAST_DB_DIR \
      --min-pct-idty $MARKER_MIN_PCT_IDTY \
      -o $CHRONOSTRAIN_TARGET_JSON \
      --threads $NUM_CORES
