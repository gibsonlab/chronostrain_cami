#!/bin/bash
source settings_global.sh
source mgems/settings.sh
set -e


aln_and_compress()
{
	in1=$1
	in2=$2
	aln1=$3
	aln2=$4
	tmp_dir=$5
	ref_index=$6
	index_num_colors=$7

	input_file=${tmp_dir}/query_files.txt
  output_file=${tmp_dir}/output_files.txt
	aln_raw1=${tmp_dir}/aln1.txt
	aln_raw2=${tmp_dir}/aln2.txt

	# prepare input txt file list
  echo "${in1}" > "$input_file"
  echo "${in2}" >> "$input_file"

  echo "${aln_raw1}" > "$output_file"
  echo "${aln_raw2}" >> "$output_file"

	themisto pseudoalign \
    --index-prefix "${ref_index}" --rc --temp-dir ${tmp_dir} --n-threads ${N_CORES} --sort-output-lines \
    --query-file-list "$input_file" \
    --out-file-list "$output_file" \

  n1=$(wc -l < "${aln_raw1}")
  n2=$(wc -l < "${aln_raw2}")
  echo "alignment-writer -n ${index_num_colors} -r $n1 -f $aln_raw1 > $aln1"
  alignment-writer -n ${index_num_colors} -r $n1 -f $aln_raw1 > $aln1
  echo "alignment-writer -n ${index_num_colors} -r $n2 -f $aln_raw2 > $aln2"
  alignment-writer -n ${index_num_colors} -r $n2 -f $aln_raw2 > $aln2
}


run_mgems_species() {
  outdir=$1
  fq1=$2
  fq2=$3
  subdir=${outdir}/species

  # Check if reads are valid.
  if [ ! -f "${fq1}" ] || [ ! -f "${fq2}" ]; then
    echo "[! Error] Read input files 1.fq.gz and/or 2.fq.gz not found. Skipping sample ${sample_id}"
    return
  fi

  # Breadcrumb files.
  run_breadcrumb="${subdir}/step.DONE"

  # Run analysis
  if [ -f "${run_breadcrumb}" ]; then
    echo "[!] mGEMS species-level binning for ${sample_id} already done."
    return
  fi

  # Species-level binning.
  tmpdir="${subdir}/__tmp"
  aln1="${subdir}/aln_1.aln"
  aln2="${subdir}/aln_2.aln"

  set +e
  mkdir -p "${tmpdir}"
  echo "[* Themisto - Species] Aligning reads."
  aln_and_compress "$fq1" "$fq2" "$aln1" "$aln2" "$tmpdir" "${SPECIES_REF_DIR}/${SPECIES_REF_INDEX}" "${SPECIES_N_COLORS}"

  echo "[* mSWEEP - Species] Running mSWEEP abundance estimation."
  # TODO -- does this require more groups via --target-groups?
  mSWEEP \
    -t "${N_CORES}" \
    --themisto-1 "${aln1}" --themisto-2 "${aln2}"  \
    -o "${subdir}/msweep" \
    -i "${SPECIES_REF_DIR}/${SPECIES_REF_CLUSTER}" \
    --bin-reads \
    --target-groups "Escherichia_coli,Staphylococcus_aureus,Streptococcus_pneumoniae,Klebsiella_pneumoniae" \
    --min-abundance 0.0 \
    --verbose

  echo "[* mGEMS - Species] Running mGEMS extract."
  mkdir -p "${subdir}/binned_reads"
  mv "${subdir}/Escherichia_coli.bin" "${subdir}/binned_reads/Escherichia_coli.bin"
  mv "${subdir}/Staphylococcus_aureus.bin" "${subdir}/binned_reads/Staphylococcus_aureus.bin"
  mv "${subdir}/Streptococcus_pneumoniae.bin" "${subdir}/binned_reads/Streptococcus_pneumoniae.bin"
  mv "${subdir}/Klebsiella_pneumoniae.bin" "${subdir}/binned_reads/Klebsiella_pneumoniae.bin"

  cd "${subdir}"  # for some reason, mGEMS extract only works if you cd into the directory.
  mGEMS extract --bins binned_reads/Escherichia_coli.bin -r ${fq1},${fq2} -o binned_reads
  mGEMS extract --bins binned_reads/Staphylococcus_aureus.bin -r ${fq1},${fq2} -o binned_reads
  mGEMS extract --bins binned_reads/Streptococcus_pneumoniae.bin -r ${fq1},${fq2} -o binned_reads
  mGEMS extract --bins binned_reads/Klebsiella_pneumoniae.bin -r ${fq1},${fq2} -o binned_reads
  cd -

  echo "[*] Cleaning up."
  set -e
  rm -rf "${tmpdir}"
  touch "${run_breadcrumb}"
}


run_mgems_strain() {
  outdir=$1
  species_name=$2
  subdir=${outdir}/${species_name}
  fq1=${outdir}/species/binned_reads/${species_name}_1.fastq.gz
  fq2=${outdir}/species/binned_reads/${species_name}_2.fastq.gz

  # Check if reads are valid.
  if [ ! -f "${fq1}" ] || [ ! -f "${fq2}" ]; then
    echo "[! Error] Species-binned for ${species_name} not found. (Check in ${outdir}/species)"
    return
  fi

  # Breadcrumb files.
  run_breadcrumb="${subdir}/step.DONE"

  # Run analysis
  if [ -f "${run_breadcrumb}" ]; then
    echo "[!] mSWEEP strain-level quantification for ${sample_id} already done."
    return
  fi

  # Strain-level profiling.
  tmpdir="${subdir}/__tmp"
  aln1="${subdir}/aln_1.aln"
  aln2="${subdir}/aln_2.aln"

  mkdir -p "${tmpdir}"
  echo "[* Themisto - ${species_name}] Aligning reads."
  set +e
  aln_and_compress "$fq1" "$fq2" "$aln1" "$aln2" "$tmpdir" "${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}/${MGEMS_GOLD_STANDARD_ONLY_REF_INDEX}" "${MGEMS_GOLD_STANDARD_ONLY_N_COLORS}"

  echo "[* mSWEEP - ${species_name}] Running mSWEEP abundance estimation."
  mSWEEP \
    -t "${N_CORES}" \
    --themisto-1 "${aln1}" --themisto-2 "${aln2}"  \
    -o "${subdir}/msweep" \
    -i "${MGEMS_GOLD_STANDARD_ONLY_REF_DIR}/${MGEMS_GOLD_STANDARD_ONLY_REF_CLUSTER}"

  echo "[*] Cleaning up."
  set -e
  rm -rf "${tmpdir}"
  touch "${run_breadcrumb}"
}


run_mgems_hierarchical() {
  sample_id=$1
  outdir="${DATA_DIR}/inference/output/mgems_gold_standard_only/sample_${sample_id}"

  fq1="${DATA_DIR}/reads/extracted/sample_${sample_id}/1.fq.gz"
  fq2="${DATA_DIR}/reads/extracted/sample_${sample_id}/2.fq.gz"

  run_mgems_species "$outdir" "$fq1" "$fq2"
  run_mgems_strain "$outdir" "Escherichia_coli"
  run_mgems_strain "$outdir" "Staphylococcus_aureus"
  run_mgems_strain "$outdir" "Streptococcus_pneumoniae"
  run_mgems_strain "$outdir" "Klebsiella_pneumoniae"
}


i=0
echo "[* mgems_gold_standard_only] Handling sample ${i}..."
run_mgems_hierarchical "${i}"