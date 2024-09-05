from pathlib import Path
import requests

# Pre-defined variables.
GOLD_STANDARD_DIR = Path("/mnt/e/CAMI_strain_madness/gold_standard_genomes")
GOLD_STANDARD_TAR = GOLD_STANDARD_DIR / "strmgCAMI2_genomes.tar.gz"
GOLD_STANDARD_URL = "https://frl.publisso.de/data/frl:6425521/strain/strmgCAMI2_genomes.tar.gz"


def download_file(url, target_path, chunk_size=8192):
    """ https://stackoverflow.com/questions/16694907/download-large-file-in-python-with-requests """
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(target_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=chunk_size):
                f.write(chunk)


def ensure_gold_standard_exists():
    if not GOLD_STANDARD_TAR.exists():
        print("downloading gold standard genomes ().".format(GOLD_STANDARD_TAR.name))
        download_file(GOLD_STANDARD_URL, GOLD_STANDARD_TAR)
