#!/bin/bash
source settings_global.sh
source mgems/settings.sh
set -e

################
# This script constructs a themisto index for each species, using gold standard plus
# reference genomes downloaded from NCBI datasets.
################


create_strain_index() {
  db_dir=$1
  genus=$2
  species=$3
  reference_ncbi_index=$4
  out_index=$5
  out_msweep_clusters=$6


  ## Prepare directory.
  mkdir -p "${db_dir}"
  cd "${db_dir}" || exit 1
  echo "Working in ${db_dir}"


  ## create poppunk input
  mkdir -p poppunk
  cd poppunk || exit 1

  echo "[!] Preparing PopPUNK inputs."
  grep "^${genus}\s" "${GOLD_STANDARD_INDEX}" | grep "\s${species}\s" | cut -f4,6 > poppunk_input.tsv  # no need to use sed 1d here, since the grep removes the header.
  grep "^${genus}\s" "${reference_ncbi_index}" | grep "\s${species}\s" | cut -f4,6 >> poppunk_input.tsv

  ## run poppunk
  echo "[!] Running PopPUNK database construction."
  poppunk --create-db --r-files poppunk_input.tsv --threads "${N_CORES}" --output database


  ## run clustering
  echo "[!] Running PopPUNK clustering."
  threshold_value=0.0000000001
  poppunk --fit-model threshold --ref-db database --threshold "${threshold_value}" --output threshold --threads "${N_CORES}"


  cd ..
  ## Create the ref_info.tsv file, using sed+join.
  # the first "sed" skips the first line.
  # the second "sed" fixes accessions (poppunk replaces the versioning dot in the bio accession with an underscore, so undo it.)
  echo "[!] Preparing mGEMS input index files."
  echo -e "id\tcluster\tassembly" > ref_info.tsv
  join -1 1 -2 1 <(sed '1d' poppunk/threshold/threshold_clusters.csv | sed -E 's/([0-9])_/\1./' | tr ',' '\t' | sort) <(sort poppunk/poppunk_input.tsv) | tr ' ' '\t' >> ref_info.tsv


  ## Build themisto index.  (IMPORTANT!!! that we use 'cut' to extract directly from ref_paths.txt, to preserve reference ordering in the database between themisto and mSWEEP)
  cut -f3 ref_info.tsv | sed '1d' > ref_paths.txt
  mkdir -p __tmp
  echo "[!] Running themisto build."
  themisto build -k 31 -i ref_paths.txt -o "${out_index}" --temp-dir __tmp


  echo "[!] Cleaning up.."
  ## mSWEEP aux files.
  cut -f2 ref_info.tsv | sed '1d' > "${out_msweep_clusters}"
}


create_strain_index "${MGEMS_ECOLI_DB_DIR}" "Escherichia" "coli" "${ECOLI_NCBI_INDEX}" "${MGEMS_ECOLI_HYBRID_REF_INDEX}" "${MGEMS_ECOLI_HYBRID_REF_CLUSTER}"


## Create a table translating msweep cluster index to gold-standard ID.
#echo -e "ID\tFasta\tCluster" > ref_info.tsv
## filter gold-standard index by genus and species, then extract only the fasta file path.
#sed '1d' "${GOLD_STANDARD_INDEX}" | grep "^${genus}\s" | grep "\s${species}\s" | cut -f3,6 | awk -v OFS='\t' '{print $1,$2,NR-1}' >> ref_info.tsv
#sed '1d' "${reference_ncbi_index}" | cut -f3,6 | awk -v OFS='\t' '{print $1,$2,NR-1}' >> ref_info.tsv
#
## Extract the list of fasta file paths.
## sed | cut: skip the first line (header) and extract sixth column (fasta path).
#sed '1d' ref_info.tsv | cut -f2 > themisto_ref_paths.txt
#
## Build themisto index.
#mkdir __tmp
#themisto build -k 31 -i themisto_ref_paths.txt -o "${MGEMS_ECOLI_HYBRID_REF_INDEX}" --temp-dir __tmp
#rm -rf __tmp
#
#
## Create mSWEEP aux file (list of cluster IDs --- one per gold standard. Not running poppunk here)
#sed '1d' ref_info.tsv | cut -f3 > "${MGEMS_ECOLI_HYBRID_REF_CLUSTER}"
