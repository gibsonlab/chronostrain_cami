#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
set -e


out_subdir=$1
database_json=$2


num_fastq_reads() {
  fq_gz_file=$1
  num_lines=$(pigz -dc "$fq_gz_file" | wc -l | awk '{print $1}')
	num_reads=$((${num_lines} / 4))
	echo "${num_reads}"
}


pipeline_single_sample() {
  sample_id=$1
  outdir="${DATA_DIR}/inference/output/${out_subdir}/sample_${sample_id}"
  logdir=${outdir}/logs

  # Breadcrumb files.
  filter_breadcrumb="${outdir}/filter.DONE"
  inference_breadcrumb="${outdir}/inference.DONE"

  # Run filtering
  if [ -f "${filter_breadcrumb}" ]; then
    echo "[!] Filtering for ${sample_id} already done."
  else
    # Prepare input files and directories
    fq1="${DATA_DIR}/reads/extracted/sample_${sample_id}/1.fq.gz"
    fq2="${DATA_DIR}/reads/extracted/sample_${sample_id}/2.fq.gz"
    if [ ! -f "${fq1}" ] || [ ! -f "${fq2}" ]; then
      echo "[! Error] Read input files 1.fq.gz and/or 2.fq.gz not found."
      exit 1
    fi
    n_fwd=$(num_fastq_reads "$fq1")
    n_rev=$(num_fastq_reads "$fq2")
    if [ "${n_fwd}" -ne "${n_rev}" ]; then
      echo "[! Error] Sample ${sample_id} forward reads (${n_fwd}) don't match reverse reads (${n_rev})."
      exit 1
    fi

    mkdir -p "${outdir}"
    mkdir -p "${logdir}"
    reads_csv="${outdir}/reads.csv"
    echo "${DEFAULT_T},SAMPLE_${sample_id},${n_fwd},${fq1},paired_1,fastq" > "${reads_csv}"
    echo "${DEFAULT_T},SAMPLE_${sample_id},${n_rev},${fq2},paired_2,fastq" >> "${reads_csv}"

    # Invoke CLI interface.
    env JAX_PLATFORM_NAME=cpu \
      CHRONOSTRAIN_DB_JSON="${database_json}" \
      CHRONOSTRAIN_DB_DIR="${CHRONOSTRAIN_DB_DIR}" \
      CHRONOSTRAIN_LOG_FILEPATH="${logdir}/filter.log" \
      CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
      chronostrain filter \
      -r "${reads_csv}" \
      -o "${outdir}/filtered" \
      -f "filtered_reads.csv" \
      --aligner bwa-mem2
    touch "${filter_breadcrumb}"
  fi

  # Inference: No clusters passed for this run!
  if [ -f "${inference_breadcrumb}" ]; then
    echo "[!] Inference for ${sample_id} already done."
  else
    expected_filter_file="${outdir}/filtered/filtered_reads.csv"
    env \
      CHRONOSTRAIN_DB_JSON="${database_json}" \
      CHRONOSTRAIN_DB_DIR="${CHRONOSTRAIN_DB_DIR}" \
      CHRONOSTRAIN_LOG_FILEPATH="${logdir}/inference.log" \
      CHRONOSTRAIN_CACHE_DIR="${CHRONOSTRAIN_CACHE_DIR}/${out_subdir}" \
      chronostrain advi \
      -r "${expected_filter_file}" \
      -o "${outdir}" \
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
      --with-zeros \
      --prior-p 0.001
    touch "${inference_breadcrumb}"
  fi
}

for i in $(seq 0 99); do
  echo "[* ${out_subdir}] Handling sample ${i}..."
  pipeline_single_sample "${i}"
done

