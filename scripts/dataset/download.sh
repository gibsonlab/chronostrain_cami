#!/bin/bash
# Run this script to download the fastQ synthetic reads from CAMI2 strain-madness dataset.

TARBALLS_DIR=/mnt/e/CAMI_strain_madness/reads/tarballs
mkdir -p ${TARBALLS_DIR}

# Sequential solution
for i in $(seq 0 99); do
  echo "Handling sample ${i}..."
  target_file="${TARBALLS_DIR}/sample_${i}_reads.tar.gz"
  if [ -f $target_file ]; then
      echo "Target tarball ${target_file} already exists."
      continue
  fi
  wget --tries 100 "https://frl.publisso.de/data/frl:6425521/strain/short_read/strmgCAMI2_sample_${i}_reads.tar.gz" -O "$target_file"
done

## Parallel solution
#NUM_PARALLEL=10
#lftp -c 'mget -c -P ${NUM_PARALLEL} -O ${TARBALLS_DIR} https://frl.publisso.de/data/frl:6425521/strain/short_read/*_reads.tar.gz; exit'
