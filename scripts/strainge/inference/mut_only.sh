#!/bin/bash
source settings_global.sh
source strainge/settings.sh


run_straingst() {
  sample_id=$1
  outdir="${DATA_DIR}/inference/output/straingst_mut_only/sample_${sample_id}"

  # Breadcrumb files.
  run_breadcrumb="${outdir}/strainGST.DONE"

  # Run analysis
  if [ -f "${run_breadcrumb}" ]; then
    echo "[! straingst_mut_only] StrainGST analysis for ${sample_id} already done."
    return
  fi

  fq1_paired="${DATA_DIR}/reads/extracted/sample_${sample_id}/1_paired.fq.gz"
  fq2_paired="${DATA_DIR}/reads/extracted/sample_${sample_id}/2_paired.fq.gz"
  if [ ! -f "${fq1_paired}" ] || [ ! -f "${fq2_paired}" ]; then
    echo "[! Error] Read input files not found. Skipping sample ${sample_id}"
    return
  fi

  # Perform StrainGST kmerization + analysis.
  mkdir -p "${outdir}"
  read_kmers="${outdir}/reads.hdf5"
  if [ -f "${read_kmers}" ]; then
    echo "[! straingst_mut_only] Kmerization already done for ${sample_id}."
  else
    echo "[! straingst_mut_only StrainGST] Read_1: ${fq1_paired}"
    echo "[! straingst_mut_only StrainGST] Read_2: ${fq2_paired}"
    echo "[! straingst_mut_only StrainGST] Kmerizing reads."
    straingst kmerize -k 23 -o "${read_kmers}" "${fq1_paired}" "${fq2_paired}"
  fi

  echo "[! straingst_mut_only StrainGST] Running StrainGST algorithm."
  results_tsv="${outdir}/result.tsv"
  num_iters=408
  min_score=0
  straingst run \
    -o "${results_tsv}" \
    -i "${num_iters}" \
    "${STRAINGE_MUT_ONLY_DB}" "${read_kmers}" \
    -s "${min_score}" \
    --separate-output
  rm "${read_kmers}"
  touch "${run_breadcrumb}"
}


for i in $(seq 0 99); do
  echo "[* straingst_mut_only] Handling sample ${i}..."
  run_straingst "${i}"
done

