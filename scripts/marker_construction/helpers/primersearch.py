from typing import *
from pathlib import Path
from chronostrain.util.external import call_command

from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqFeature import SimpleLocation
from Bio.Emboss import PrimerSearch


def invoke_primersearch(ref_seq_path: Path, in_path: Path, out_path: Path, cluster_name: str, primer1: Seq, primer2: Seq, mismatch_pct: int):
    # Prepare input file for `primersearch` EMBOSS program.
    primer_search_input = PrimerSearch.InputRecord()
    primer_search_input.add_primer_set(cluster_name, primer1, primer2)
    with open(in_path, 'wt') as f:
        print(str(primer_search_input), file=f)

    # Invoke the program.
    call_command(
        'primersearch',
        args=[
            '-seqall', ref_seq_path,
            '-infile', in_path,
            '-mismatchpercent', mismatch_pct,
            '-outfile', out_path
        ],
        silent=False
    )


def parse_primersearch_output(out_path: Path) -> Iterator[SimpleLocation]:
    with open(out_path, 'rt') as f:
        for line in f:
            if len(line.strip()) == 0:
                continue
            elif line.startswith("Primer name"):
                continue
            elif line.startswith("Amplimer"):
                continue
            elif 'hits forward strand' in line:
                i = line.index('at ')
                j = line.index(' with')
                fwd_pos = int(line[i+len('at '):j].strip())
            elif 'hits reverse strand' in line:
                continue
            elif line.startswith("\tAmplimer length:"):
                # this occurs at the end of a section.
                bp_token = line.strip()[len("Amplimer length:"):-len("bp")]
                try:
                    bp_len = int(bp_token)
                    yield SimpleLocation(start=fwd_pos-1, end=fwd_pos + bp_len - 1, strand=+1)
                except ValueError:
                    raise ValueError("Couldn't parse len from token {}".format(bp_token)) from None


class GeneSequence:
    def __init__(self, name: str, seq: Seq):
        self.name = name
        self.seq = seq

    def __str__(self):
        return "{}:{}".format(self.name, self.seq)

    def __repr__(self):
        return "{}<len={}|seq={}>".format(self.name, len(self.seq), self.seq)


def get_primerhit_as_gene(
        chrom_path: Path,
        cluster_name: str,
        primer1: Seq,
        primer2: Seq,
        mismatch_pct: int,
        tmp_dir: Path
) -> GeneSequence:
    # =========== primersearch
    in_path = tmp_dir / 'primer_input.txt'
    out_path = tmp_dir / 'primer_output.txt'
    invoke_primersearch(
        chrom_path, in_path, out_path,
        f"gene__{cluster_name}",
        primer1, primer2,
        mismatch_pct
    )

    # =========== parse gene features.
    genome_seq = SeqIO.read(chrom_path, "fasta")

    # =========== parse primersearch
    hits = list(parse_primersearch_output(out_path))
    if len(hits) > 1:
        print(f"Found multiple candidate hits for {cluster_name}.")
        for target_loc in hits:
            print(f"Found loc: {target_loc}")
            gene_seq = GeneSequence(
                name=cluster_name,
                seq=target_loc.extract(genome_seq).seq
            )
            print(repr(gene_seq))
        raise Exception("Ambiguous gene!")
    elif len(hits) == 0:
        raise Exception(f"Found no hits for gene {cluster_name}.")

    target_loc = hits[0]
    return GeneSequence(name=cluster_name, seq=target_loc.extract(genome_seq).seq)
    