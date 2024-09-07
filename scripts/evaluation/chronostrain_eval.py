from typing import *
from pathlib import Path

import numpy as np
import scipy
import pandas as pd
from collections import Counter

from chronostrain.inference import GaussianWithGlobalZerosPosteriorDense
from chronostrain.config import cfg
from base import StrainAbundanceProfile


class ChronoStrainInferenceResult:
    def __init__(
            self,
            posterior: GaussianWithGlobalZerosPosteriorDense,
            inference_strains: List[str],
            adhoc_clusters: Dict[str, str]
    ):
        self.posterior = posterior
        self.inference_strains = inference_strains
        self.inference_ordering: Dict[str, int] = {s: i for i, s in enumerate(inference_strains)}
        self.adhoc_clusters = adhoc_clusters
        self.adhoc_clust_sizes = Counter()
        for s_id, s_rep_id in adhoc_clusters.items():
            self.adhoc_clust_sizes[s_rep_id] += 1

    def get_samples(self, n_samples: int) -> np.ndarray:
        rand = self.posterior.random_sample(n_samples)
        g_samples = np.array(
            self.posterior.reparametrized_gaussians(rand['std_gaussians'], self.posterior.get_parameters())
        )  # T x N x S
        z_samples = np.array(
            self.posterior.reparametrized_zeros(rand['std_gumbels'], self.posterior.get_parameters())
        )  # N x S
        return g_samples, z_samples

    def posterior_inclusion_probs(self):
        return scipy.special.expit(-self.posterior.get_parameters()['gumbel_diff'])

    def adhoc_cluster_info(self, strain_id: str) -> Tuple[int, int]:
        adhoc_rep_id = self.adhoc_clusters[strain_id]
        return self.inference_ordering[adhoc_rep_id], self.adhoc_clust_sizes[adhoc_rep_id]

    def to_profile(
            self,
            strain_id_ordering: List[str],
            posterior_lb: float = 0.9901,
            n_samples: int = 5000
    ) -> StrainAbundanceProfile:
        g, z = self.get_samples(n_samples)

        # Filter by posterior
        posterior_p = self.posterior_inclusion_probs()
        indicators = posterior_p > posterior_lb

        log_indicators = np.empty(indicators.shape, dtype=float)
        log_indicators[indicators] = 0.0
        log_indicators[~indicators] = -np.inf

        pred_abundances_wrapped = scipy.special.softmax(g + np.expand_dims(log_indicators, axis=[0, 1]), axis=-1)

        # Fill in the prediction matrix. (Undo the ad-hoc clustering by dividing the abundance.)
        predictions = np.empty(shape=(n_samples, len(strain_id_ordering)), dtype=float)
        for tgt_idx, tgt_strain in enumerate(strain_id_ordering):
            adhoc_idx, adhoc_clust_sz = self.adhoc_cluster_info(tgt_strain)
            predictions[:, tgt_idx] = pred_abundances_wrapped[0, :, adhoc_idx] / adhoc_clust_sz

        return StrainAbundanceProfile(
            abundance_ratios=predictions / np.sum(predictions, axis=-1, keepdims=True),
            strain_ids=strain_id_ordering
        )


def parse_chronostrain_strains(txt_file: Path) -> List[str]:
    with open(txt_file, 'rt') as f:
        return [x.strip() for x in f]


def parse_adhoc_clusters(txt_file: Path) -> Dict[str, str]:
    clust = {}
    with open(txt_file, "rt") as f:
        for line in f:
            tokens = line.strip().split(":")
            rep = tokens[0]
            members = tokens[1].split(",")
            for member in members:
                clust[member] = rep
    return clust


def parse_posterior_model(posterior_file: Path, d_strains: int) -> GaussianWithGlobalZerosPosteriorDense:
    posterior = GaussianWithGlobalZerosPosteriorDense(d_strains, 1, cfg.engine_cfg.dtype)
    posterior.load(posterior_file)
    return posterior


def extract_chronostrain_prediction(inference_dir: Path) -> ChronoStrainInferenceResult:
    strain_list = parse_chronostrain_strains(inference_dir / "strains.txt")
    return ChronoStrainInferenceResult(
        parse_posterior_model(inference_dir / f"posterior.{cfg.engine_cfg.dtype}.npz", len(strain_list)),
        strain_list,
        parse_adhoc_clusters(inference_dir / "adhoc_cluster.txt"),
    )
