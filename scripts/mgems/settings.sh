export MGEMS_DB_DIR="/mnt/e/CAMI_strain_madness/inference/databases/mgems"
export N_CORES=6

# re-use the same large taxonomic db from the other experiments.
export MGEMS_SPECIES_REF_DIR="/mnt/e/semisynthetic_data/databases/mgems/themisto_640k"
export MGEMS_SPECIES_REF_INDEX=index
export MGEMS_SPECIES_REF_CLUSTER=index_mSWEEP_indicators.txt
export MGEMS_SPECIES_N_COLORS=2340

export MGEMS_ECOLI_DB_DIR="${MGEMS_DB_DIR}/e_coli"
export MGEMS_ECOLI_HYBRID_REF_INDEX=gold_with_reference_index
export MGEMS_ECOLI_HYBRID_REF_CLUSTER=gold_with_reference_msweep_indicators.txt

export MGEMS_GOLD_STANDARD_ONLY_REF_DIR=${MGEMS_DB_DIR}/gold_standard_only
export MGEMS_GOLD_STANDARD_ONLY_REF_INDEX=themisto_index
export MGEMS_GOLD_STANDARD_ONLY_REF_CLUSTER=msweep_indicators.txt

export MGEMS_GOLD_STANDARD_MUT_REF_DIR=${MGEMS_DB_DIR}/gold_with_mut
export MGEMS_GOLD_STANDARD_MUT_REF_INDEX=themisto_index
export MGEMS_GOLD_STANDARD_MUT_REF_CLUSTER=msweep_indicators.txt

export MGEMS_MUT_ONLY_REF_DIR=${MGEMS_DB_DIR}/mut_only
export MGEMS_MUT_ONLY_REF_INDEX=themisto_index
export MGEMS_MUT_ONLY_REF_CLUSTER=msweep_indicators.txt


aln_and_compress()
{
  # This function runs themisto pseudoalignment using a specific index.
  # The logic here includes alignment file compression (using alignment-writer).
  # Does not provide cleanups of tmp_dir.
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
export aln_and_compress
