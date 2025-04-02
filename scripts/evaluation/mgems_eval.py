from typing import *
from pathlib import Path

import numpy as np
import pandas as pd
from base import StrainAbundanceProfile


class MGEMSFlatInferenceResult:
    def __init__(self, abund_df: pd.DataFrame):
        self.abund_df = abund_df

    def to_profile(
            self,
            strain_id_ordering: List[str],
            mgems_abund_lb: float,
            renormalize: bool = False
    ):
        predictions = np.empty(shape=(len(strain_id_ordering),), dtype=float)
        for tgt_idx, tgt_strain in enumerate(strain_id_ordering):
            strain_hit_rows = self.abund_df.loc[self.abund_df['ID'] == tgt_strain, 'Abundance']
            if strain_hit_rows.shape[0] != 1:
                raise ValueError(f"Found more than one entry containing strain ID {tgt_strain}. Unable to resolve ambiguity.")
            elif strain_hit_rows.shape[0] == 0:
                raise ValueError(f"Unable to locate strain ID {tgt_strain} in mSWEEP output dataframe.")
            else:
                pred_value = strain_hit_rows.head(1).item()
                if pred_value > mgems_abund_lb:
                    predictions[tgt_idx] = pred_value
                else:
                    predictions[tgt_idx] = 0.0
        if renormalize:
            predictions = predictions / np.sum(predictions)
        return StrainAbundanceProfile(
            abundance_ratios=predictions,
            strain_ids=strain_id_ordering
        )


def msweep_parse_abundances(msweep_output_path: Path, ref_info_path: Path) -> pd.DataFrame:
    df_entries = []
    with open(msweep_output_path, "rt") as f:
        for line in f:
            line = line.strip()
            if line.startswith("#"):
                continue
            tokens = line.split("\t")
            if len(tokens) != 2:
                raise ValueError("Found {} tokens in msweep file {}, but expected 2.".format(
                    len(tokens), msweep_output_path
                ))
            df_entries.append({"Cluster": tokens[0], "Abundance": float(tokens[1])})

    cluster_df = pd.read_csv(ref_info_path, sep='\t')
    cluster_df['Cluster'] = cluster_df['Cluster'].astype(str)
    return pd.DataFrame(df_entries).merge(cluster_df, on='Cluster', how='inner')


def extract_mgems_prediction(inference_dir: Path, ref_info_path: Path) -> MGEMSFlatInferenceResult:
    return MGEMSFlatInferenceResult(
        msweep_parse_abundances(inference_dir / "msweep_abundances.txt", ref_info_path)
    )
