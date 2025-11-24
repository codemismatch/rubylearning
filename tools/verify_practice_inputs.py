import pathlib
from textwrap import indent

root = pathlib.Path(__file__).resolve().parents[1]
target = root / "content/pages/tutorials/getting-input.md"
print(target)
print(target.read_text())
