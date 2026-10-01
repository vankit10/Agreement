"""Create the iOS icon from the extracted, original company graphic."""
from pathlib import Path
from PIL import Image
import json

root = Path(__file__).resolve().parents[1]
target = root / 'AdarshAgreement/Resources/Assets.xcassets/AppIcon.appiconset'
target.mkdir(parents=True, exist_ok=True)
image = Image.open(root / 'AdarshAgreement/Resources/logo.png').convert('RGB')
canvas = Image.new('RGB', (1024, 1024), 'white')
image.thumbnail((860, 820))
canvas.paste(image, ((1024-image.width)//2, (1024-image.height)//2))
canvas.save(target / 'AppIcon.png')
(target / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2))
(target.parent / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}, indent=2))
