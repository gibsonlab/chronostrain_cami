num_fastq_reads() {
  fq_gz_file=$1
  num_lines=$(pigz -dc "$fq_gz_file" | wc -l | awk '{print $1}')
	num_reads=$((${num_lines} / 4))
	echo "${num_reads}"
}
export num_fastq_reads


pipeline_single_sample() {
  sample_id=$1
  out_subdir=$2
  db_dir=$3
  database_json=$4
  cluster_file=$5
  sparse_mode=$6

  outdir="${DATA_DIR}/inference/output/${out_subdir}/sample_${sample_id}"
  logdir=${outdir}/logs

  # Breadcrumb files.
  filter_breadcrumb="${outdir}/filtered/filter.DONE"

  # Run filtering
  if [ -f "${filter_breadcrumb}" ]; then
    echo "[! - ${out_subdir}] Filtering for ${sample_id} already done."
  else
    echo "[! - ${out_subdir}] Running filtering for ${sample_id}."
    # Prepare input files and directories
    fq1="${DATA_DIR}/reads/extracted/sample_${sample_id}/1.fq.gz"
    fq2="${DATA_DIR}/reads/extracted/sample_${sample_id}/2.fq.gz"
    if [ ! -f "${fq1}" ] || [ ! -f "${fq2}" ]; then
      echo "[! Error] Read input files 1.fq.gz and/or 2.fq.gz not found. Skipping sample ${sample_id}"
      return
    fi
    n_fwd=$(num_fastq_reads "$fq1")
    n_rev=$(num_fastq_reads "$fq2")
    if [ "${n_fwd}" -ne "${n_rev}" ]; then
      echo "[! Error] Sample ${sample_id} forward reads (N=${n_fwd}) doesn't match reverse reads (N=${n_rev})."
      exit 1
    fi

    mkdir -p "${outdir}"
    mkdir -p "${logdir}"
    reads_csv="${outdir}/reads.csv"
    echo "${DEFAULT_T},SAMPLE_${sample_id},${n_fwd},${fq1},paired_1,fastq" > "${reads_csv}"
    echo "${DEFAULT_T},SAMPLE_${sample_id},${n_rev},${fq2},paired_2,fastq" >> "${reads_csv}"

    # Invoke CLI interface.
    set +e  # terminate on error.
    env JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_JSON="${database_json}" \
      CHRONOSTRAIN_DB_DIR="${db_dir}" \
      CHRONOSTRAIN_LOG_FILEPATH="${logdir}/filter.log" \
      CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
      chronostrain filter \
      -r "${reads_csv}" \
      -o "${outdir}/filtered" \
      -s "${cluster_file}" \
      -f "filtered_reads.csv" \
      --aligner bwa-mem2
    touch "${filter_breadcrumb}"
    set -e
  fi

  if [ "${sparse_mode}" == "sparse" ]; then
    inference_outdir="${outdir}/sparse_model"
    is_sparse="True"
  elif [ "${sparse_mode}" == "dense" ]; then
    inference_outdir="${outdir}/dense_model"
    is_sparse="False"
  else
    echo "[!] Unsupported sparse_mode string ${sparse_mode}."
    exit 1
  fi


  inference_breadcrumb="${inference_outdir}/inference.DONE"
  if [ -f "${inference_breadcrumb}" ]; then
    echo "[! - ${out_subdir} | ${sparse_mode}] Inference for ${sample_id} already done."
  else
    echo "[! - ${out_subdir} | ${sparse_mode}] Running inference for ${sample_id}."
    expected_filter_file="${outdir}/filtered/filtered_reads.csv"
    set +e  # terminate on error.
    if [ "${is_sparse}" == "True" ]; then
      env \
        CHRONOSTRAIN_DB_JSON="${database_json}" \
        CHRONOSTRAIN_DB_DIR="${db_dir}" \
        CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.log" \
        CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
        chronostrain advi \
        -r "${expected_filter_file}" \
        -o "${inference_outdir}" \
        -s "${cluster_file}" \
        --correlation-mode "full" \
        --iters "${CHRONOSTRAIN_NUM_ITERS}" \
        --epochs "${CHRONOSTRAIN_NUM_EPOCHS}" \
        --decay-lr "${CHRONOSTRAIN_DECAY_LR}" \
        --lr-patience "${CHRONOSTRAIN_LR_PATIENCE}" \
        --loss-tol "${CHRONOSTRAIN_LOSS_TOL}" \
        --learning-rate "${CHRONOSTRAIN_LR}" \
        --num-samples "${CHRONOSTRAIN_NUM_SAMPLES}" \
        --read-batch-size "${CHRONOSTRAIN_READ_BATCH_SZ}" \
        --min-lr "${CHRONOSTRAIN_MIN_LR}" \
        --plot-format "pdf" \
        --plot-elbo \
        --prune-strains \
        --with-zeros  # Sparse mode
    else
      env \
        CHRONOSTRAIN_DB_JSON="${database_json}" \
        CHRONOSTRAIN_DB_DIR="${db_dir}" \
        CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.log" \
        CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
        chronostrain advi \
        -r "${expected_filter_file}" \
        -o "${inference_outdir}" \
        -s "${cluster_file}" \
        --correlation-mode "full" \
        --iters "${CHRONOSTRAIN_NUM_ITERS}" \
        --epochs "${CHRONOSTRAIN_NUM_EPOCHS}" \
        --decay-lr "${CHRONOSTRAIN_DECAY_LR}" \
        --lr-patience "${CHRONOSTRAIN_LR_PATIENCE}" \
        --loss-tol "${CHRONOSTRAIN_LOSS_TOL}" \
        --learning-rate "${CHRONOSTRAIN_LR}" \
        --num-samples "${CHRONOSTRAIN_NUM_SAMPLES}" \
        --read-batch-size "${CHRONOSTRAIN_READ_BATCH_SZ}" \
        --min-lr "${CHRONOSTRAIN_MIN_LR}" \
        --plot-format "pdf" \
        --plot-elbo \
        --prune-strains \
        --without-zeros  # Dense mode
    fi
    touch "${inference_breadcrumb}"
    set -e
  fi
}
export pipeline_single_sample

