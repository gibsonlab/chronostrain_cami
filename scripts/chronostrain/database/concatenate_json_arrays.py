from typing import List
import json
from pathlib import Path
import click


@click.command()
@click.option(
    '--input', '-i', 'input_paths',
    multiple=True,
    type=click.Path(path_type=Path, dir_okay=False, exists=True, readable=True),
    required=True,
    help="A path to a JSON file containing a single list. Repeat this argument to specify a list. "
         "(example: -i file1 -i file2 -i file3)"
)
@click.option(
    '--output', '-o', 'out_path',
    type=click.Path(path_type=Path, dir_okay=False, exists=False),
    required=True,
    help="An output JSON path."
)
def main(input_paths: List[Path], out_path: Path):
    master_array = []
    for file_path in input_paths:
        with open(file_path, "rt") as json_f:
            instance_array = json.load(json_f)
            assert isinstance(instance_array, List)
            master_array += instance_array

    with open(out_path, "wt") as out_f:
        json.dump(master_array, out_f)


if __name__ == "__main__":
    main()
