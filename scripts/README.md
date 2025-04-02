# Contents of this codebase
This codebase contains bash scripts which implement the CAMI strain-madness analysis pipeline found in the 
benchmaking section of the paper "Longitudinal profiling of low-abundance strains in microbiomes with ChronoStrain".
(https://doi.org/10.1038/s41564-025-01983-z)


# Instructions

Prior to running anything, first set the desired data directories in `settings_global.sh`:
```
...
export DATA_DIR="<your_empty_data_dir>"
```

All scripts are meant to be run from this (scripts/) directory.
Example:
```bash
bash dataset/download.sh
bash dataset/extract.sh
bash chronostrain/inference/ecoli_gold_standard_onlyu.sh
```

# Step 1: Download dataset.

```bash
bash dataset/download.sh
bash dataset/download_gold_standard.sh
bash dataset/extract.sh
bash dataset/trim.sh
```

# Step 2: Database construction.

```bash
bash chronostrain/database/gold_standard_only.sh
bash mgems/database/gold_standard_only.sh
bash strainge/database/gold_standard_only.sh
```

# Step 3: Inference

```bash
bash chronostrain/inference/all_gold_standard.sh
bash mgems/inference/gold_standard_only.sh
bash strainge/inference/gold_standard_only.sh
```

# Step 4: Evaluation

Open the notebook `evaluation/evaluate.ipynb` and run all cells.
