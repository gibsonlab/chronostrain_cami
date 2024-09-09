export MGEMS_DB_DIR="/mnt/e/CAMI_strain_madness/inference/databases/mgems"

# re-use the same large taxonomic db from the other experiments.
export SPECIES_REF_DIR="/mnt/e/semisynthetic_data/databases/mgems/themisto_640k"
export SPECIES_REF_INDEX=index
export SPECIES_REF_CLUSTER=index_mSWEEP_indicators.txt
export SPECIES_N_COLORS=2340

export MGEMS_GOLD_STANDARD_ONLY_REF_DIR=${MGEMS_DB_DIR}/gold_standard_only
export MGEMS_GOLD_STANDARD_ONLY_REF_INDEX=themisto_index
export MGEMS_GOLD_STANDARD_ONLY_REF_CLUSTER=msweep_indicators.txt
export MGEMS_GOLD_STANDARD_ONLY_N_COLORS=408
