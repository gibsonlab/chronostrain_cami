from typing import *
from pathlib import Path

import numpy as np
import pandas as pd
from base import StrainAbundanceProfile


class StrainGEInferenceResult:
    def __init__(self, result_df: pd.DataFrame):
        self.result_df = result_df

    def to_profile(
            self,
            strain_id_ordering: List[str]
    ):
        predictions = np.empty(shape=(len(strain_id_ordering),), dtype=float)
        for tgt_idx, tgt_strain in enumerate(strain_id_ordering):
            strain_hit_rows = self.result_df.loc[self.result_df['strain'] == tgt_strain, 'rapct']
            if strain_hit_rows.shape[0] > 1:
                raise ValueError(f"Found more than one entry containing strain ID {tgt_strain}. Unable to resolve ambiguity.")
            elif strain_hit_rows.shape[0] == 0:
                predictions[tgt_idx] = 0.0
            else:
                predictions[tgt_idx] = strain_hit_rows.head(1).item() / 100.0
        return StrainAbundanceProfile(
            abundance_ratios=predictions / np.sum(predictions, axis=-1, keepdims=True),
            strain_ids=strain_id_ordering
        )


def extract_straingst_prediction(inference_dir: Path) -> StrainGEInferenceResult:
    tsv_file = inference_dir / "result.strains.tsv"
    return StrainGEInferenceResult(pd.read_csv(tsv_file, sep='\t', index_col="i"))
