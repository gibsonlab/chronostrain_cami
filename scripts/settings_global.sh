export DATA_DIR="/mnt/e/CAMI_strain_madness"
export SCRIPT_DIR=$(pwd)
export MISC_DATA_DIR=${SCRIPT_DIR}/../data

export GOLD_STANDARD_DIR=${DATA_DIR}/gold_standard_genomes
export GOLD_STANDARD_GZ=${GOLD_STANDARD_DIR}/archives/strmgCAMI2_genomes.tar.gz
export GOLD_STANDARD_INDEX="${GOLD_STANDARD_DIR}/index.tsv"

export CHRONOSTRAIN_INI="chronostrain/chronostrain.ini"
export CHRONOSTRAIN_LOG_INI="chronostrain/logging.ini"

export GROUND_TRUTH_PROFILE_SRC="${MISC_DATA_DIR}/gs_strain_madness_short_long.profile.txt"
