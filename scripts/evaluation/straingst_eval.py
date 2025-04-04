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
            strain_id_ordering: List[str],
            score_lb: float,
            renormalize: bool = False
    ):
        predictions = np.empty(shape=(len(strain_id_ordering),), dtype=float)
        for tgt_idx, tgt_strain in enumerate(strain_id_ordering):
            strain_hit_rows = self.result_df.loc[self.result_df['strain'] == tgt_strain, :]
            if strain_hit_rows.shape[0] > 1:
                raise ValueError(f"Found more than one entry containing strain ID {tgt_strain}. Unable to resolve ambiguity.")
            elif strain_hit_rows.shape[0] == 0:
                predictions[tgt_idx] = 0.0
            else:
                score = strain_hit_rows['score'].head(1).item()
                if score > score_lb:
                    predictions[tgt_idx] = strain_hit_rows['rapct'].head(1).item() / 100.0
                else:
                    predictions[tgt_idx] = 0.0
        if renormalize:
            predictions = predictions / np.sum(predictions)
        return StrainAbundanceProfile(
            abundance_ratios=predictions,
            strain_ids=strain_id_ordering
        )


def extract_straingst_prediction(inference_dir: Path) -> StrainGEInferenceResult:
    tsv_file = inference_dir / "result.strains.tsv"
    return StrainGEInferenceResult(pd.read_csv(tsv_file, sep='\t', index_col="i"))
