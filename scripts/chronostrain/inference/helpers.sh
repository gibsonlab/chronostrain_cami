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

  echo "[!] Inference will be run using ${database_json}"

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
    fq1_paired="${DATA_DIR}/reads/extracted/sample_${sample_id}/1_paired.fq.gz"
    fq2_paired="${DATA_DIR}/reads/extracted/sample_${sample_id}/2_paired.fq.gz"
    if [ ! -f "${fq1_paired}" ] || [ ! -f "${fq2_paired}" ]; then
      echo "[! Error] Read input files not found. Skipping sample ${sample_id}"
      exit 1
    fi

    n_fwd_paired=$(num_fastq_reads "$fq1_paired")
    n_rev_paired=$(num_fastq_reads "$fq2_paired")
    if [ "${n_fwd_paired}" -ne "${n_rev_paired}" ]; then
      echo "[! Error] Sample ${sample_id} forward reads (N=${n_fwd_paired}) doesn't match reverse reads (N=${n_rev_paired})."
      exit 1
    fi

    mkdir -p "${outdir}"
    mkdir -p "${logdir}"
    reads_csv="${outdir}/reads.csv"
    echo "${DEFAULT_T},SAMPLE_${sample_id}_PAIRED,${n_fwd_paired},${fq1_paired},paired_1,fastq" > "${reads_csv}"
    echo "${DEFAULT_T},SAMPLE_${sample_id}_PAIRED,${n_rev_paired},${fq2_paired},paired_2,fastq" >> "${reads_csv}"
#    echo "${DEFAULT_T},SAMPLE_${sample_id}_UNPAIRED_1,${n_fwd_unpaired},${fq1_unpaired},paired_1,fastq" >> "${reads_csv}"
#    echo "${DEFAULT_T},SAMPLE_${sample_id}_UNPAIRED_2,${n_rev_unpaired},${fq2_unpaired},paired_2,fastq" >> "${reads_csv}"

    # Invoke CLI interface.
    set -e  # terminate on error.
    env JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_JSON="${database_json}" \
      CHRONOSTRAIN_DB_DIR="${db_dir}" \
      CHRONOSTRAIN_LOG_FILEPATH="${logdir}/filter.log" \
      CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
      chronostrain filter \
      -r "${reads_csv}" \
      -o "${outdir}/filtered" \
      -f "filtered_reads.csv" \
      --identity-threshold 0.9 \
      --aligner bwa-mem2
    touch "${filter_breadcrumb}"
    set +e
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
    set -e  # terminate on error.
    if [ "${is_sparse}" == "True" ]; then
      env \
        CHRONOSTRAIN_DB_JSON="${database_json}" \
        CHRONOSTRAIN_DB_DIR="${db_dir}" \
        CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.sparse.log" \
        CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
        chronostrain advi \
        -r "${expected_filter_file}" \
        -o "${inference_outdir}" \
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
        --adhoc-corr-threshold "${CHRONOSTRAIN_ADHOC_THRESHOLD}" \
        --with-zeros  # Sparse mode
    else
      env \
        CHRONOSTRAIN_DB_JSON="${database_json}" \
        CHRONOSTRAIN_DB_DIR="${db_dir}" \
        CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.dense.log" \
        CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
        chronostrain advi \
        -r "${expected_filter_file}" \
        -o "${inference_outdir}" \
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
        --adhoc-corr-threshold "${CHRONOSTRAIN_ADHOC_THRESHOLD}" \
        --without-zeros  # Dense mode
    fi
    touch "${inference_breadcrumb}"
    set +e
  fi
}
export pipeline_single_sample


pipeline_multi_sample() {
  sample_id_start=$1
  out_subdir=$2
  db_dir=$3
  database_json=$4
  cluster_file=$5
  sparse_mode=$6
  batch_size=$7

  sample_id_end=$((sample_id_start + batch_size - 1))

  outdir="${DATA_DIR}/inference/output/${out_subdir}/sample_batch_${sample_id_start}_${sample_id_end}"
  logdir=${outdir}/logs

  # Breadcrumb files.
  filter_breadcrumb="${outdir}/filtered/filter.DONE"

  # Run filtering
  if [ -f "${filter_breadcrumb}" ]; then
    echo "[! - ${out_subdir}] Filtering for ${sample_id_start} - ${sample_id_end} already done."
  else
    echo "[! - ${out_subdir}] Running filtering for ${sample_id_start} - ${sample_id_end}."

    mkdir -p "${outdir}"
    mkdir -p "${logdir}"
    reads_csv="${outdir}/reads.csv"
    > "${reads_csv}"
    time_dt=10.0
    t=10.0
    for sample_i in $(seq ${sample_id_start} ${sample_id_end}); do
      echo "[! - ${out_subdir}] Appending sample ${sample_i}"
      # Prepare input files and directories
      fq1_paired="${DATA_DIR}/reads/extracted/sample_${sample_id}/1_paired.fq.gz"
#      fq1_unpaired="${DATA_DIR}/reads/extracted/sample_${sample_id}/1_unpaired.fq.gz"
      fq2_paired="${DATA_DIR}/reads/extracted/sample_${sample_id}/2_paired.fq.gz"
#      fq2_unpaired="${DATA_DIR}/reads/extracted/sample_${sample_id}/2_unpaired.fq.gz"
      if [ ! -f "${fq1_paired}" ] || [ ! -f "${fq2_paired}" ]; then
        echo "[! Error] Read input files not found. Skipping sample ${sample_id}"
        exit 1
      fi

      n_fwd_paired=$(num_fastq_reads "$fq1_paired")
#      n_fwd_unpaired=$(num_fastq_reads "$fq1_unpaired")
      n_rev_paired=$(num_fastq_reads "$fq2_paired")
#      n_rev_unpaired=$(num_fastq_reads "$fq2_unpaired")
      if [ "${n_fwd_paired}" -ne "${n_rev_paired}" ]; then
        echo "[! Error] Sample ${sample_id} forward reads (N=${n_fwd_paired}) doesn't match reverse reads (N=${n_rev_paired})."
        exit 1
      fi

      echo "${t},SAMPLE_${sample_id}_PAIRED,${n_fwd_paired},${fq1_paired},paired_1,fastq" >> "${reads_csv}"
      echo "${t},SAMPLE_${sample_id}_PAIRED,${n_rev_paired},${fq2_paired},paired_2,fastq" >> "${reads_csv}"
#      echo "${t},SAMPLE_${sample_id}_UNPAIRED_1,${n_fwd_unpaired},${fq1_unpaired},paired_1,fastq" >> "${reads_csv}"
#      echo "${t},SAMPLE_${sample_id}_UNPAIRED_2,${n_rev_unpaired},${fq2_unpaired},paired_2,fastq" >> "${reads_csv}"

      t=$(echo "$t + $time_dt" | bc)
    done

    # Invoke CLI interface.
    set -e  # terminate on error.
    env JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_JSON="${database_json}" \
      CHRONOSTRAIN_DB_DIR="${db_dir}" \
      CHRONOSTRAIN_LOG_FILEPATH="${logdir}/filter.log" \
      CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
      chronostrain filter \
      -r "${reads_csv}" \
      -o "${outdir}/filtered" \
      -f "filtered_reads.csv" \
      --aligner bwa-mem2 \
      --identity-threshold 0.9 \
      --attach-sample-ids
    touch "${filter_breadcrumb}"
    set +e
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
    echo "[! - ${out_subdir} | ${sparse_mode}] Inference for batch ${sample_id_start} - ${sample_id_end} already done."
  else
    echo "[! - ${out_subdir} | ${sparse_mode}] Running inference for batch ${sample_id_start} - ${sample_id_end}."
    expected_filter_file="${outdir}/filtered/filtered_reads.csv"
    set -e  # terminate on error.
    if [ "${is_sparse}" == "True" ]; then
      env \
        CHRONOSTRAIN_DB_JSON="${database_json}" \
        CHRONOSTRAIN_DB_DIR="${db_dir}" \
        CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.sparse.log" \
        CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
        chronostrain advi \
        -r "${expected_filter_file}" \
        -o "${inference_outdir}" \
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
        --adhoc-corr-threshold "${CHRONOSTRAIN_ADHOC_THRESHOLD}" \
	      --accumulate-gradients \
        --with-zeros  # sparse mode
    else
      env \
        CHRONOSTRAIN_DB_JSON="${database_json}" \
        CHRONOSTRAIN_DB_DIR="${db_dir}" \
        CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.dense.log" \
        CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
        chronostrain advi \
        -r "${expected_filter_file}" \
        -o "${inference_outdir}" \
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
        --adhoc-corr-threshold "${CHRONOSTRAIN_ADHOC_THRESHOLD}" \
	      --accumulate-gradients \
        --without-zeros  # Dense mode
    fi
    touch "${inference_breadcrumb}"
    set +e
  fi
}
export pipeline_multi_sample
