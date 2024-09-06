from dataclasses import dataclass
from typing import List, Iterator, Tuple
from pathlib import Path

import numpy as np
import pandas as pd

from .base import StrainAbundanceProfile


@dataclass
class SpeciesLabel:
    genus: str
    species: str


def profile_split_by_sample(profile_path: Path) -> Iterator[List[str]]:
    """
    Split the huge profile.txt file into chunks of profiles, grouped by sample.
    :param profile_path:
    :return: A generator of chunks of the lines in the file. No filtering is done whatsoever.
    """
    with open(profile_path, 'rt') as profile_f:
        this_section = []
        for line in profile_f:
            line = line.rstrip('\n')  # strip newlines, but not tabs
            if len(line) == 0:
                continue

            if line.startswith("@SampleID"):
                # We are in a new section. Yield what we have so far and then start anew.
                if len(this_section) > 0:
                    yield this_section
                this_section = [line]
            else:
                this_section.append(line)
        if len(this_section) > 0:
            yield this_section


def filter_profiles(profile_path: Path) -> Iterator[Tuple[str, pd.DataFrame]]:
    for profile_text in profile_split_by_sample(profile_path):
        sample_id_line = profile_text[0]
        prefix = '@SampleID:'
        assert sample_id_line.startswith(prefix)

        sample_tag = sample_id_line[len(prefix):]
        sample_prefix = "strmgCAMI2_short_read_sample_"
        if sample_tag.startswith(sample_prefix):
            yield sample_tag, parse_profile_into_dataframe(profile_text)
        else:
            # this is either a hybrid- or a long-read sample.
            continue


def parse_profile_into_dataframe(profile_text: List[str]) -> pd.DataFrame:
    """
    Helper for filter_profiles(). Parses text-formatted profile into a dataframe.
    """
    df_entries = []
    for line in profile_text:
        if line.startswith('@'):
            continue
        if len(line) == 0:
            continue

        taxid, rank, taxpath, taxpath_scientific, percentage, cami_genome_id, cami_otu_id = line.split('\t')
        df_entries.append({
            'TaxId': taxid,
            'Rank': rank,
            'TaxPath': taxpath,
            'TaxPathScientific': taxpath_scientific,
            'Percentage': float(percentage),
            'CAMI_Genome': cami_genome_id,
            'CAMI_OTU': cami_otu_id
        })
    return pd.DataFrame(df_entries)


def renormalize_profile(profile_df: pd.DataFrame, restrict_species: SpeciesLabel) -> StrainAbundanceProfile:
    target_str = rf"\|{restrict_species.genus} {restrict_species.species}\|"
    
    strain_df = profile_df.loc[profile_df['Rank'] == 'strain']
    strain_slice = strain_df.loc[strain_df['TaxPathScientific'].str.contains(target_str)]
    
    strain_ids = list(strain_slice['CAMI_Genome'])  # the gold-standard IDs.
    abundances = strain_slice['Percentage'].to_numpy() / 100.0

    return StrainAbundanceProfile(
        abundance_ratios=abundances / np.sum(abundances),
        strain_ids=strain_ids
    )
