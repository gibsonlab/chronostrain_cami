#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh

bash chronostrain/inference/chronostrain_pipeline.sh "chronostrain_all" "${CHRONOSTRAIN_ALL_JSON}"
