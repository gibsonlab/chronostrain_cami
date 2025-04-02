from typing import Iterator, Tuple, Set, List
from pathlib import Path

import pickle
import bz2
import gzip

from Bio import SeqIO
from Bio.SeqRecord import SeqRecord


class MetaphlanParser(object):
    def __init__(self, metaphlan_pkl_path: Path):
        self.pkl_path = metaphlan_pkl_path
        self.marker_fasta = metaphlan_pkl_path.with_suffix('.fna.gz')
        if not self.marker_fasta.exists():
            raise FileNotFoundError(f"Expected {self.marker_fasta} to exist, but not found.")

    def retrieve_marker_seeds(self, target_taxon_key: str) -> Iterator[Tuple[str, str, SeqRecord]]:
        """
        Generator over Tuples (metaphlan marker ID, metaphlan taxonomic token, SeqRecord)
        """
        print(f"Searching for marker seeds from MetaPhlAn database: {self.pkl_path.stem}.")
        with bz2.open(self.pkl_path, "r") as f:
            db = pickle.load(f)

        markers = db['markers']
        marker_ids = set()
        for marker_key, marker_dict in markers.items():  # Iterate through metaphlan markers
            if target_taxon_key in marker_dict['taxon']:  # this is a string "in" operation.
                marker_ids.add(marker_key)

        print(f"Target # of markers: {len(marker_ids)}")
        for record in self._retrieve_from_fasta(marker_ids):
            marker_key = record.id
            record = SeqRecord(record.seq, id=marker_key, description=self.pkl_path.stem)
            yield marker_key, record

    def _retrieve_from_fasta(self, marker_keys: Set[str]) -> SeqRecord:
        remaining = set(marker_keys)
        with gzip.open(self.marker_fasta, "rt") as f:
            for record in SeqIO.parse(f, "fasta"):
                if len(remaining) == 0:
                    break  # Terminate early if we finished the search.
                if record.id not in remaining:
                    continue

                remaining.remove(record.id)
                yield record
        if len(remaining) > 0:
            print(f"For some reason, couldn't locate {len(remaining)} markers from Fasta: {remaining}")
