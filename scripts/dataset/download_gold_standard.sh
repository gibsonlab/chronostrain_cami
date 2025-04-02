#!/bin/bash
source settings_global.sh
# Run this script to download (and index!!) the gold-standard genomes.
seq_dir=${GOLD_STANDARD_DIR}/sequences

# Step 1. Download
if [ ! -f "${GOLD_STANDARD_GZ}" ]; then
  wget "https://frl.publisso.de/data/frl:6425521/strain/strmgCAMI2_genomes.tar.gz" -O "${GOLD_STANDARD_GZ}"
fi


# Step 2. Extract
mkdir -p "${seq_dir}"
tar -xvzf "${GOLD_STANDARD_GZ}" -C "${seq_dir}"
for f in ${seq_dir}/short_read/source_genomes/*.fasta; do
  pigz $f
  mv ${f}.gz ${seq_dir}/
done

# Step 3. Build the index.
echo -e "Genus\tSpecies\tStrain\tAccession\tAssembly\tSeqPath\tChromosomeLen\tGFF" > "${GOLD_STANDARD_INDEX}"
echo ${seq_dir}
for fasta_gz_path in ${seq_dir}/*.fasta.gz; do
  # Build the index, row by row.
  fasta_gz_file=$(basename ${fasta_gz_path})
  asm_name="${fasta_gz_file%%.*}"
#  genus_name=$(grep "${asm_name}" "${GROUND_TRUTH_PROFILE_SRC}" | head -n 1 | cut -f4 | cut -d "|" -f 6)
#  species_name=$(grep "${asm_name}" "${GROUND_TRUTH_PROFILE_SRC}" | head -n 1 | cut -f4 | cut -d "|" -f 7 | cut -d " " -f2)
  full_species_name=$(grep "${asm_name}" "${GROUND_TRUTH_PROFILE_SRC}" | head -n 1 | cut -f4 | cut -d "|" -f 7)
  genus_name=$(echo "${full_species_name}" | cut -d " " -f1)
  species_name=$(echo "${full_species_name}" | cut -d " " -f2)
  species_special_name=$(echo "${full_species_name}" | cut -d " " -f3)

  if [ "${species_name}" == "" ]; then species_name="Unknown"; fi
  if [ "${genus_name}" == "" ]; then genus_name="Unknown"; fi

  if [ "${species_name}" == "sp." ]; then
    echo -e "${genus_name}\tsp.${species_special_name}\t${asm_name}\t${asm_name}\t${asm_name}\t${seq_dir}/${fasta_gz_file}\t0\t" >> "${GOLD_STANDARD_INDEX}"
  else
    echo -e "${genus_name}\t${species_name}\t${asm_name}\t${asm_name}\t${asm_name}\t${seq_dir}/${fasta_gz_file}\t0\t" >> "${GOLD_STANDARD_INDEX}"
  fi
done

# Clean up.
rm -rf "${seq_dir}/short_read"
