#!/bin/bash
source settings_global.sh
set -e

from_incl=$1
to_incl=$2
if [ -z "$from_incl" ]; then
  from_incl=0
fi
if [ -z "$to_incl" ]; then
  to_incl=99
fi

echo "Extracting samples from ${from_incl} to ${to_incl} inclusive."



deinterleave_fastq() {
  fastq_file=$1
  fwd_file=$2
  rev_file=$3

  # https://www.biostars.org/p/141256/
  paste - - - - - - - - < "${fastq_file}" \
    | tee >(cut -f 1-4 | tr "\t" "\n" > ${fwd_file}) \
    | cut -f 5-8 | tr "\t" "\n" > ${rev_file}
}


deinterleave_fastq_gz() {
  fq_gz_file=$1
  fwd_gz_file=$2
  rev_gz_file=$3

  # define and create temporary dir.
  work_dir=$(dirname "$fwd_gz_file")
  work_dir=$work_dir/__deinterleave_tmp
  mkdir -p $work_dir

  # contents of temporary dir
  fq_file_tmp=$work_dir/__reads.fq
  fwd_tmp=$work_dir/__1.fq
  rev_tmp=$work_dir/__2.fq

  # decompress.
  pigz -dck $fq_gz_file > $fq_file_tmp

  # invoke deinterleave into temporary outputs.
  deinterleave_fastq $fq_file_tmp $fwd_tmp $rev_tmp

  # now compress, and clean up.
  pigz -c $fwd_tmp > $fwd_gz_file
  pigz -c $rev_tmp > $rev_gz_file
  rm -rf $work_dir
}


tarballs_dir=${DATA_DIR}/reads/tarballs
extract_dir=${DATA_DIR}/reads/extracted


for i in $(seq ${from_incl} ${to_incl}); do
  # Target files.
  target_dir="${extract_dir}/sample_${i}"
  target_fwd="${target_dir}/1.fq.gz"
  target_rev="${target_dir}/2.fq.gz"

  # Check if targets already exist (done in a previous run.)
  if [ -f "${target_fwd}" ]; then
    echo "[! SUCCESS] Sample ${i} already extracted. Skipping."
    continue
  fi

  # Check if archive exists.
  tar_file="${tarballs_dir}/sample_${i}_reads.tar.gz"
  if [ ! -f ${tar_file} ]; then
    echo "[! ERROR] Couldn't find tarball ${tar_file}. Skipping."
    continue
  fi

  # First, extract the tarball to a temporary location.
  echo "[!] Extracting ${i}..."
  tmp_dir=${extract_dir}/__untar_tmp
  mkdir -p ${tmp_dir}
  if tar -xvzf "${tar_file}" -C "${tmp_dir}"; then
    echo "[! SUCCESS] Successfully extracted tarball for sample ${i}."
  else
    echo "[! ERROR] Tarball for sample ${i} is not valid. Re-run download script to try again."
    #rm "${tar_file}"
    continue
  fi

  # next, deinterleave the fastq content.
  echo "[!] Deinterleaving ${i}..."
  expected_fq_gz=$(find ${tmp_dir}/short_read -name anonymous_reads.fq.gz | head 1)
  expected_mapping=$(find ${tmp_dir}/short_read -name reads_mapping.tsv.gz | head 1)
  if [ ! -f "${expected_fq_gz}" ]; then
    echo "[! ERROR] Couldn't find proper fq.gz file from extracted contents of sample ${i}."
    break
  fi
  mkdir -p "${target_dir}"
  deinterleave_fastq_gz "${expected_fq_gz}" "${target_fwd}" "${target_rev}"
  mv ${expected_mapping} ${target_dir}

  # finally, clean up.
  echo "[!] Cleaning up..."
  rm -rf "$tmp_dir"
done
