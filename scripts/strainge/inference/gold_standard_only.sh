#!/bin/bash
source settings_global.sh
source strainge/settings.sh


run_straingst() {
  sample_id=$1
  outdir="${DATA_DIR}/inference/output/straingst_gold_standard_only/sample_${sample_id}"

  # Breadcrumb files.
  run_breadcrumb="${outdir}/strainGST.DONE"

  # Run analysis
  if [ -f "${run_breadcrumb}" ]; then
    echo "[!] StrainGST analysis for ${sample_id} already done."
    return
  fi

  fq1="${DATA_DIR}/reads/extracted/sample_${sample_id}/1.fq.gz"
  fq2="${DATA_DIR}/reads/extracted/sample_${sample_id}/2.fq.gz"
  if [ ! -f "${fq1}" ] || [ ! -f "${fq2}" ]; then
    echo "[! Error] Read input files 1.fq.gz and/or 2.fq.gz not found. Skipping sample ${sample_id}"
    return
  fi

  # Perform StrainGST kmerization + analysis.
  mkdir -p "${outdir}"
  read_kmers="${outdir}/reads.hdf5"
  if [ -f "${read_kmers}" ]; then
    echo "[!] Kmerization already done for ${sample_id}."
  else
    echo "[! StrainGST] Read_1: ${fq1}"
    echo "[! StrainGST] Read_2: ${fq2}"
    echo "[! StrainGST] Kmerizing reads."
    straingst kmerize -k 23 -o "${read_kmers}" "${fq1}" "${fq2}"
  fi

  echo "[! StrainGST] Running StrainGST algorithm."
  results_tsv="${outdir}/result.tsv"
  num_iters=408
  min_score=0
  straingst run \
    -o "${results_tsv}" \
    -i "${num_iters}" \
    "${STRAINGE_GOLD_STANDARD_ONLY_DB}" "${read_kmers}" \
    -s "${min_score}" \
    --separate-output
  touch "${run_breadcrumb}"
}

