# These databases use Ecoli markers (TODO: refactor these variable names to specify this)
export CHRONOSTRAIN_DB_BASEDIR="${DATA_DIR}/inference/databases/chronostrain"

export CHRONOSTRAIN_ECOLI_DB_DIR="${CHRONOSTRAIN_DB_BASEDIR}/e_coli"
export CHRONOSTRAIN_ECOLI_GOLD_STANDARD_JSON="${CHRONOSTRAIN_ECOLI_DB_DIR}/gold_standard_only.json"
export CHRONOSTRAIN_ECOLI_GOLD_STANDARD_CLUSTERS="${CHRONOSTRAIN_ECOLI_DB_DIR}/gold_standard_only.clusters.txt"

export CHRONOSTRAIN_SAUREUS_DB_DIR="${DATA_DIR}/inference/databases/chronostrain/s_aureus"
export CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_JSON="${CHRONOSTRAIN_SAUREUS_DB_DIR}/gold_standard_only.json"
export CHRONOSTRAIN_SAUREUS_GOLD_STANDARD_CLUSTERS="${CHRONOSTRAIN_SAUREUS_DB_DIR}/gold_standard_only.clusters.txt"

export CHRONOSTRAIN_SPNEUMONIAE_DB_DIR="${DATA_DIR}/inference/databases/chronostrain/s_pneumoniae"
export CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_JSON="${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}/gold_standard_only.json"
export CHRONOSTRAIN_SPNEUMONIAE_GOLD_STANDARD_CLUSTERS="${CHRONOSTRAIN_SPNEUMONIAE_DB_DIR}/gold_standard_only.clusters.txt"

export CHRONOSTRAIN_KPNEUMONIAE_DB_DIR="${DATA_DIR}/inference/databases/chronostrain/k_pneumoniae"
export CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_JSON="${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}/gold_standard_only.json"
export CHRONOSTRAIN_KPNEUMONIAE_GOLD_STANDARD_CLUSTERS="${CHRONOSTRAIN_KPNEUMONIAE_DB_DIR}/gold_standard_only.clusters.txt"

export CHRONOSTRAIN_ALL_JSON="${CHRONOSTRAIN_DB_BASEDIR}/all.json"
export CHRONOSTRAIN_ALL_CLUSTERS="${CHRONOSTRAIN_DB_BASEDIR}/all.clusters.txt"

export CHRONOSTRAIN_REF_ONLY_JSON="/mnt/e/ecoli_db/chronostrain_files/ecoli.json"
export CHRONOSTRAIN_REF_ONLY_CLUSTERS="/mnt/e/ecoli_db/chronostrain_files/ecoli.clusters.txt"


# ========= Chronostrain settings
export CHRONOSTRAIN_CACHE_DIR="${DATA_DIR}/inference/cache/chronostrain"
export CHRONOSTRAIN_ADHOC_THREHSOLD=0.9999
export DEFAULT_T=1000.0
export CHRONOSTRAIN_NUM_ITERS=100
export CHRONOSTRAIN_NUM_SAMPLES=100
export CHRONOSTRAIN_READ_BATCH_SZ=10000
export CHRONOSTRAIN_NUM_EPOCHS=5000
export CHRONOSTRAIN_DECAY_LR=0.1
export CHRONOSTRAIN_LR=0.0005
export CHRONOSTRAIN_LOSS_TOL=1e-7
export CHRONOSTRAIN_LR_PATIENCE=5
export CHRONOSTRAIN_MIN_LR=1e-7
