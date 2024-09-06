#!/bin/bash
source settings_global.sh
source chronostrain/settings.sh

bash chronostrain/inference/chronostrain_pipeline.sh "chronostrain_gold_standard_only" "${CHRONOSTRAIN_GOLD_STANDARD_JSON}"
