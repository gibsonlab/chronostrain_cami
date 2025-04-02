from typing import List
import numpy as np


class StrainAbundanceProfile(object):
    def __init__(self, abundance_ratios: np.ndarray, strain_ids: List[str]):
        self.abundance_ratios = abundance_ratios
        self.strain_ids = strain_ids
        self.strain_to_indices = {
            s: i for i, s in enumerate(strain_ids)
        }

    def strain_index(self, strain_id: str) -> int:
        return self.strain_to_indices[strain_id]

    def get_abundance(self, strain_id: str) -> float:
        return self.abundance_ratios[..., self.strain_index(strain_id)]

    def extend(self, extended_strain_ids: List[str]) -> 'StrainAbundanceProfile':
        assert set(self.strain_ids).issubset(set(extended_strain_ids))
        assert len(self.abundance_ratios.shape) == 1
        extended_abundances = np.zeros(
            shape=len(extended_strain_ids),
            dtype=self.abundance_ratios.dtype
        )
        for ext_i, ext_id in enumerate(extended_strain_ids):
            if ext_id in self.strain_to_indices:
                extended_abundances[ext_i] = self.get_abundance(ext_id)
        return StrainAbundanceProfile(extended_abundances, extended_strain_ids)
