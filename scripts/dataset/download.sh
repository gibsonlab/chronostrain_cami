#!/bin/bash
source settings_global.sh
# Run this script to download the fastQ synthetic reads from CAMI2 strain-madness dataset.

tarballs_dir="${DATA_DIR}/reads/tarballs"
mkdir -p ${tarballs_dir}

# Sequential solution
for i in $(seq 0 99); do
  echo "Handling sample ${i}..."
  target_file="${tarballs_dir}/sample_${i}_reads.tar.gz"
  if [ -f $target_file ]; then
      echo "Target tarball ${target_file} already exists."
      continue
  fi
  wget --tries 100 "https://frl.publisso.de/data/frl:6425521/strain/short_read/strmgCAMI2_sample_${i}_reads.tar.gz" -O "$target_file"
done

## Parallel solution, outdated (file paths are also outdated!)
#NUM_PARALLEL=10
#lftp -c 'mget -c -P ${NUM_PARALLEL} -O ${tarballs_dir} https://frl.publisso.de/data/frl:6425521/strain/short_read/*_reads.tar.gz; exit'
