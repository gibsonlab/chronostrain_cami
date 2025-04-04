#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh
set -e

# Assuming the gold-standard-only database was already constructed, concatenate it with the refseq database.
python chronostrain/database/concatenate_json_arrays.py \
  -i "${CHRONOSTRAIN_GOLD_STANDARD_JSON}" \
  -i "${CHRONOSTRAIN_REF_ONLY_JSON}" \
  -o "${CHRONOSTRAIN_ALL_JSON}"


# Now add the gold-standard to the cluster file.
cat "${CHRONOSTRAIN_REF_ONLY_CLUSTERS}" "${CHRONOSTRAIN_GOLD_STANDARD_CLUSTERS}" > "${CHRONOSTRAIN_ALL_CLUSTERS}"
