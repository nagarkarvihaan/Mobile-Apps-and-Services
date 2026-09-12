"""Package backend runtime files only; never upload .env or local environments."""
from pathlib import Path
import argparse
import zipfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('output', type=Path)
args = parser.parse_args()
files = ['app.py', 'domain.py', 'gunicorn.conf.py', 'requirements.txt',
         'services/gemini_service.py']
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in files:
        archive.write(root / 'backend' / name, name)
print(f'Packaged {len(files)} runtime files; no credentials included.')
