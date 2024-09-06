from typing import List
import numpy as np


class StrainAbundanceProfile(object):
    def __init__(self, abundance_ratios: np.ndarray, strain_ids: List[str]):
        self.abundance_ratios = abundance_ratios
        self.strain_ids = strain_ids
