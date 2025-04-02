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

echo "Trimming samples from ${from_incl} to ${to_incl} inclusive."



invoke_trimmomatic() {
  fwd_gz_file=$1
  rev_gz_file=$2

  trimmomatic PE -phred33 -threads 6 -quiet \
    ${fwd_gz_file} ${rev_gz_file} \
    1_paired.fq.gz 1_unpaired.fq.gz \
    2_paired.fq.gz 2_unpaired.fq.gz \
    LEADING:5 \
    TRAILING:5 \
    MINLEN:36
}


reads_dir=${DATA_DIR}/reads/extracted


for i in $(seq ${from_incl} ${to_incl}); do
  # Target files.
  target_dir="${reads_dir}/sample_${i}"
  echo "Trimming samples in: ${target_dir}"

  # Check if targets already exist (done in a previous run.)
  if [ -f "${target_dir}/trimmomatic.DONE" ]; then
    echo "[! SUCCESS] Sample ${i} already trimmed. Skipping."
    continue
  fi

  cd "${target_dir}"
  invoke_trimmomatic "1.fq.gz" "2.fq.gz"
  touch "trimmomatic.DONE"
  echo "[! SUCCESS] Successfully trimmed sample ${i}."
  cd -
done
