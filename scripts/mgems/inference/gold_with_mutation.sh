#!/bin/bash
source settings_global.sh
source mgems/settings.sh
set -e


run_mgems_gold_with_mut() {
  outdir=$1
  fq1=$2
  fq2=$3

  # Check if reads are valid.
  if [ ! -f "${fq1}" ] || [ ! -f "${fq2}" ]; then
    echo "[! mgems:gold_with_mut Error] Read input files 1.fq.gz and/or 2.fq.gz not found. Skipping sample ${sample_id}"
    return
  fi

  # Breadcrumb files.
  run_breadcrumb="${outdir}/step.DONE"

  # Run analysis
  if [ -f "${run_breadcrumb}" ]; then
    echo "[! mgems:gold_with_mut] mGEMS quantification for ${sample_id} already done."
    return
  fi

  # Species-level binning.
  tmpdir="${outdir}/__tmp"
  aln1="${outdir}/aln_1.aln"
  aln2="${outdir}/aln_2.aln"

  set -e
  mkdir -p "${tmpdir}"
  echo "[* mgems:gold_with_mut Themisto] Aligning reads."
  n_colors=$(wc -l ${MGEMS_GOLD_STANDARD_MUT_REF_DIR}/themisto_ref_paths.txt | awk '{ print $1 }')
  echo "[* mgems:gold_with_mut] Target refdir = ${MGEMS_GOLD_STANDARD_MUT_REF_DIR}, colors=${n_colors}"
  aln_and_compress "$fq1" "$fq2" "$aln1" "$aln2" "$tmpdir" "${MGEMS_GOLD_STANDARD_MUT_REF_DIR}/${MGEMS_GOLD_STANDARD_MUT_REF_INDEX}" "${n_colors}"

  echo "[* mSWEEP - gold_with_mut] Running mSWEEP abundance estimation."
  # No need to bin reads here. Not running hierarchical mode.
  mSWEEP \
    -t "${N_CORES}" \
    --themisto-1 "${aln1}" --themisto-2 "${aln2}"  \
    -o "${outdir}/msweep" \
    -i "${MGEMS_GOLD_STANDARD_MUT_REF_DIR}/${MGEMS_GOLD_STANDARD_MUT_REF_CLUSTER}" \
    --verbose

  echo "[*] Cleaning up."
  set +e
  rm -rf "${tmpdir}"
  touch "${run_breadcrumb}"
}


run_mgems_pipeline() {
  sample_id=$1
  outdir="${DATA_DIR}/inference/output/mgems_gold_with_mutation/sample_${sample_id}"

  fq1="${DATA_DIR}/reads/extracted/sample_${sample_id}/1_paired.fq.gz"
  fq2="${DATA_DIR}/reads/extracted/sample_${sample_id}/2_paired.fq.gz"

  run_mgems_gold_with_mut "$outdir" "$fq1" "$fq2"
}


for i in $(seq 0 99); do
  echo "[* mgems:gold_with_mut] Handling sample ${i}..."
  run_mgems_pipeline "${i}"
done
