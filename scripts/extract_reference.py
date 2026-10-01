"""Extract original graphics and measured geometry without altering source files."""
from pathlib import Path
from pypdf import PdfReader
import pdfplumber
import json
import shutil

root = Path(__file__).resolve().parents[1]
source = Path('/Users/ankitverma/Downloads/new one.pdf')
reader = PdfReader(source)
assets = root / 'AdarshAgreement/Resources'
names = {'Image5': 'logo', 'Image7': 'construction', 'Image9': 'construction-detail',
         'Image13': 'instagram', 'Image14': 'facebook', 'Image24': 'watermark'}
for image in reader.pages[0].images:
    stem = image.name.split('.')[0]
    if stem in names:
        image.image.save(assets / (names[stem] + '.png'))
shutil.copy2(source, root / 'reference/source.pdf')
shutil.copy2('/Users/ankitverma/Downloads/Adarsh_Agreement_App_PRD.docx', root / 'reference/requirements.docx')
with pdfplumber.open(source) as pdf:
    measurement = []
    for page in pdf.pages:
        measurement.append({'width': page.width, 'height': page.height,
                            'fonts': sorted(set((c['fontname'], round(c['size'], 2)) for c in page.chars)),
                            'images': [{k: im[k] for k in ('name','x0','top','width','height')} for im in page.images],
                            'text': page.extract_text()})
    (root / 'reference/geometry.json').write_text(json.dumps(measurement, indent=2))
print('Extracted reference graphics and geometry')
