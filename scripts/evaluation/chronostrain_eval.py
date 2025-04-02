from typing import *
from pathlib import Path

import json
import gzip
from Bio import SeqIO

import numpy as np
import scipy
import pandas as pd
from collections import Counter

from chronostrain.inference import GaussianWithGlobalZerosPosteriorDense, GaussianPosteriorFullReparametrizedCorrelation
from chronostrain.config import cfg
from base import StrainAbundanceProfile


class ChronoStrainInferenceResult:
    def __init__(
            self,
            posterior: Union[GaussianWithGlobalZerosPosteriorDense, GaussianPosteriorFullReparametrizedCorrelation],
            inference_strains: List[str],
            adhoc_clusters: Dict[str, str],
            filtered_read_counts: List[int],
            total_read_counts: List[int],
            marker_genome_ratios: Dict[str, float]
    ):
        self.posterior = posterior
        self.inference_strains = inference_strains
        self.inference_ordering: Dict[str, int] = {s: i for i, s in enumerate(inference_strains)}
        if adhoc_clusters is None:
            self.adhoc_clusters = {s: s for s in inference_strains}
        else:
            self.adhoc_clusters = adhoc_clusters
        self.adhoc_clust_sizes = Counter()
        for s_id, s_rep_id in self.adhoc_clusters.items():
            self.adhoc_clust_sizes[s_rep_id] += 1

        self.filtered_read_counts = filtered_read_counts
        self.total_read_counts = total_read_counts
        self.marker_genome_ratios = marker_genome_ratios

    def get_samples(self, n_samples: int) -> np.ndarray:
        if isinstance(self.posterior, GaussianWithGlobalZerosPosteriorDense):
            rand = self.posterior.random_sample(n_samples)
            g_samples = np.array(
                self.posterior.reparametrized_gaussians(rand['std_gaussians'], self.posterior.get_parameters())
            )  # T x N x S
            z_samples = np.array(
                self.posterior.reparametrized_zeros(rand['std_gumbels'], self.posterior.get_parameters())
            )  # N x S
            return g_samples, z_samples
        elif isinstance(self.posterior, GaussianPosteriorFullReparametrizedCorrelation):
            rand = self.posterior.random_sample(n_samples)
            return self.posterior.reparametrize(rand, self.posterior.get_parameters())
        else:
            raise RuntimeError("Unsupported type of posterior: {}".format(type(self.posterior)))

    def posterior_inclusion_probs(self):
        return scipy.special.expit(-self.posterior.get_parameters()['gumbel_diff'])

    def adhoc_cluster_info(self, strain_id: str) -> Tuple[int, int]:
        adhoc_rep_id = self.adhoc_clusters[strain_id]
        return self.inference_ordering[adhoc_rep_id], self.adhoc_clust_sizes[adhoc_rep_id]

    def to_profile(
            self,
            strain_id_ordering: List[str],
            timepoint_index: int = 0,
            posterior_lb: float = 0.9901,
            n_samples: int = 5000,
            renormalize: bool = False
    ) -> StrainAbundanceProfile:
        if isinstance(self.posterior, GaussianWithGlobalZerosPosteriorDense):
            g, z = self.get_samples(n_samples)
            
            # Filter by posterior
            posterior_p = self.posterior_inclusion_probs()
            indicators = posterior_p > posterior_lb
    
            log_indicators = np.empty(indicators.shape, dtype=float)
            log_indicators[indicators] = 0.0
            log_indicators[~indicators] = -np.inf
            if np.sum(indicators) == 0:
                print("All indicators were turned off at this threshold.")
    
            pred_abundances_adhoc_wrapped = scipy.special.softmax(g + np.expand_dims(log_indicators, axis=[0, 1]), axis=-1)  # (T x N x S)
        elif isinstance(self.posterior, GaussianPosteriorFullReparametrizedCorrelation):
            g = self.get_samples(n_samples)
            pred_abundances_adhoc_wrapped = scipy.special.softmax(g, axis=-1)  # (T x N x S)

        # Take the timepoint slice.
        pred_abundances_adhoc_wrapped = pred_abundances_adhoc_wrapped[timepoint_index]  # (N x S)

        # Now, convert to overall relative abundance.
        marker_genome_ratios = np.array([self.marker_genome_ratios[s_id] for s_id in self.inference_strains])
        weighted_abundances = pred_abundances_adhoc_wrapped * np.expand_dims(marker_genome_ratios, axis=0)  # (N x S)
        db_to_marker_ratio = np.reciprocal(np.sum(weighted_abundances, axis=-1))  # (N)
        marker_to_total_ratio = self.filtered_read_counts[timepoint_index] / self.total_read_counts[timepoint_index]  # (scalar)
        overall_conversion_ratio = db_to_marker_ratio * marker_to_total_ratio  # (N)
        pred_abundances_adhoc_wrapped = pred_abundances_adhoc_wrapped * np.expand_dims(overall_conversion_ratio, axis=1)

        # Fill in the prediction matrix. (Undo the ad-hoc clustering by dividing the abundance.)
        predictions = np.empty(shape=(n_samples, len(strain_id_ordering)), dtype=float)
        for tgt_idx, tgt_strain in enumerate(strain_id_ordering):
            adhoc_idx, adhoc_clust_sz = self.adhoc_cluster_info(tgt_strain)
            predictions[:, tgt_idx] = pred_abundances_adhoc_wrapped[:, adhoc_idx] / adhoc_clust_sz

        if renormalize:
            predictions = predictions / np.sum(predictions, axis=-1, keepdims=True)
            
        return StrainAbundanceProfile(
            abundance_ratios=predictions,
            strain_ids=strain_id_ordering
        )

    def presence_scores(
        self, 
        strain_id_ordering: List[str],
        n_samples: int = 5000
    ):
        if isinstance(self.posterior, GaussianWithGlobalZerosPosteriorDense):
            g, z = self.get_samples(n_samples)
            
            # Filter by posterior
            posterior_p = self.posterior_inclusion_probs()
        elif isinstance(self.posterior, GaussianPosteriorFullReparametrizedCorrelation):
            raise NotImplementedError("Presence/Absence prediction is not implemented for this posterior.")

        # Fill in the prediction matrix. (Undo the ad-hoc clustering by dividing the abundance.)
        predictions = np.empty(shape=len(strain_id_ordering), dtype=float)
        for tgt_idx, tgt_strain in enumerate(strain_id_ordering):
            adhoc_idx, adhoc_clust_sz = self.adhoc_cluster_info(tgt_strain)
            predictions[tgt_idx] = posterior_p[adhoc_idx]

        return predictions


def parse_chronostrain_strains(txt_file: Path) -> List[str]:
    with open(txt_file, 'rt') as f:
        return [x.strip() for x in f]


def parse_adhoc_clusters(txt_file: Path) -> Dict[str, str]:
    if not txt_file.exists():
        return None

    clust = {}
    with open(txt_file, "rt") as f:
        for line in f:
            tokens = line.strip().split(":")
            rep = tokens[0]
            members = tokens[1].split(",")
            for member in members:
                clust[member] = rep
    return clust


def parse_posterior_model_sparse(posterior_file: Path, d_strains: int, n_timepoints: int) -> GaussianWithGlobalZerosPosteriorDense:
    posterior = GaussianWithGlobalZerosPosteriorDense(d_strains, n_timepoints, cfg.engine_cfg.dtype)
    posterior.load(posterior_file)
    return posterior


def parse_posterior_model_dense(posterior_file: Path, d_strains: int, n_timepoints: int) -> GaussianPosteriorFullReparametrizedCorrelation:
    posterior = GaussianPosteriorFullReparametrizedCorrelation(d_strains, n_timepoints, cfg.engine_cfg.dtype)
    posterior.load(posterior_file)
    return posterior


def extract_read_counts(filtered_read_index: Path) -> Tuple[np.ndarray, np.ndarray]:
    if filtered_read_index.suffix.lower() == '.csv':
        sep = ','
    elif filtered_read_index.suffix.lower() == '.tsv':
        sep = '\t'
    else:
        raise ValueError(f"Supported file extensions for input files are (.csv, .tsv). Got: {filtered_read_index.suffix}")
    input_df = pd.read_csv(
        filtered_read_index,
        sep=sep,
        header=None,
        names=['T', 'SampleName', 'ReadDepth', 'ReadPath', 'ReadType', 'QualityFormat']
    ).astype(
        {
            'T': 'float32',
            'SampleName': 'string',
            'ReadDepth': 'int64',
            'ReadPath': 'string',
            'ReadType': 'string',
            'QualityFormat': 'string'
        }
    ).sort_values("T", ascending=True)
    total_read_counts = input_df.groupby("T")['ReadDepth'].sum().to_numpy()
    time_points = input_df['T'].drop_duplicates().to_numpy()

    filtered_read_counts = np.array([
        sum(extract_filtered_read_counts(filtered_read_index.parent / Path(row['ReadPath']).name) for _, row in time_slice.iterrows())
        for t, time_slice in input_df.groupby("T")
    ])
    return filtered_read_counts, total_read_counts


def extract_filtered_read_counts(fastq_path: Path) -> int:
    # Take a shortcut; instead of reading from the fastq file, just sum up the columns in the filter metadata file.
    basename = fastq_path.name.split(".")[0]
    metadata_path = fastq_path.parent / f"{basename}.metadata.tsv"
    metadata_df = pd.read_csv(metadata_path, sep='\t')
    return metadata_df['PASSED_FILTER'].sum()


def calculate_marker_genome_ratio(db_json_file: Path) -> Dict[str, float]:
    with open(db_json_file, "rt") as f:
        json_raw = json.load(f)

    ratios = {}
    for strain_entry in json_raw:
        seq_file = strain_entry['seqs'][0]['seq_path']
        s_id = strain_entry['id']
        with gzip.open(seq_file, "rt") as seq_f:
            genome_length = sum(len(record.seq) for record in SeqIO.parse(seq_f, "fasta"))
        marker_length = sum(marker['end'] - marker['start'] + 1 for marker in strain_entry['markers'])
        ratios[s_id] = marker_length / genome_length
    return ratios


def extract_chronostrain_prediction(
    inference_dir: Path, 
    sparse: bool, 
    marker_genome_ratios: Dict[str, float], 
    n_timepoints: int = 1
) -> ChronoStrainInferenceResult:
    if not (inference_dir / "inference.DONE").exists():
        raise FileNotFoundError(f"Inference in {inference_dir} is not done.")
    strain_list = parse_chronostrain_strains(inference_dir / "strains.txt")
    if sparse:
        posterior = parse_posterior_model_sparse(inference_dir / f"posterior.{cfg.engine_cfg.dtype}.npz", len(strain_list), n_timepoints)
    else:
        posterior = parse_posterior_model_dense(inference_dir / f"posterior.{cfg.engine_cfg.dtype}.npz", len(strain_list), n_timepoints)

    filtered_read_file = inference_dir.parent / 'filtered' / 'filtered_reads.csv'
    filtered_read_counts, total_read_counts = extract_read_counts(filtered_read_file)
    return ChronoStrainInferenceResult(
        posterior,
        strain_list,
        parse_adhoc_clusters(inference_dir / "adhoc_cluster.txt"),
        filtered_read_counts,
        total_read_counts,
        marker_genome_ratios
    )

