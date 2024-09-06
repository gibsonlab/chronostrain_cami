# These databases use Ecoli markers (TODO: refactor these variable names to specify this)
export CHRONOSTRAIN_DB_DIR="${DATA_DIR}/inference/databases/chronostrain/ecoli"
export CHRONOSTRAIN_GOLD_STANDARD_JSON="${CHRONOSTRAIN_DB_DIR}/gold_standard_only.json"
export CHRONOSTRAIN_GOLD_STANDARD_CLUSTERS="${CHRONOSTRAIN_DB_DIR}/gold_standard_only.clusters.txt"

export CHRONOSTRAIN_ALL_JSON="${CHRONOSTRAIN_DB_DIR}/all.json"
export CHRONOSTRAIN_ALL_CLUSTERS="${CHRONOSTRAIN_DB_DIR}/all.clusters.txt"

export CHRONOSTRAIN_REF_ONLY_JSON="/mnt/e/ecoli_db/chronostrain_files/ecoli.json"
export CHRONOSTRAIN_REF_ONLY_CLUSTERS="/mnt/e/ecoli_db/chronostrain_files/ecoli.clusters.txt"


# ========= Chronostrain settings
export CHRONOSTRAIN_CACHE_DIR="${DATA_DIR}/inference/cache/chronostrain"
export DEFAULT_T=1000.0
export CHRONOSTRAIN_NUM_ITERS=100
export CHRONOSTRAIN_NUM_SAMPLES=100
export CHRONOSTRAIN_READ_BATCH_SZ=10000
export CHRONOSTRAIN_NUM_EPOCHS=5000
export CHRONOSTRAIN_DECAY_LR=0.1
export CHRONOSTRAIN_LR=0.00001
export CHRONOSTRAIN_LOSS_TOL=1e-7
export CHRONOSTRAIN_LR_PATIENCE=5
export CHRONOSTRAIN_MIN_LR=1e-7
