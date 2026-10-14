I am currently searching for any prior manifest templates or project goal examples to ensure exact schema compliance. I will proceed as soon as the search completes.
I am verifying any occurrences of `locale_text_keys` across files to inspect potential schema examples.
I will wait briefly for the search task to complete.
I will wait for `flutter analyze` to finish to ensure the project passes analysis.
I am waiting for `flutter analyze` to finish.
I am standing by for `flutter analyze` to complete.
`flutter analyze` arka planda çalışıyor, tamamlanmasını bekliyorum.
`flutter analyze` komutunun tamamlanmasını bekliyorum.
## What I changed

- [`assets/asset_manifest.json`](file:///D:/github/farm%20world/assets/asset_manifest.json) — Farm World pilot görsel varlıkları için makine tarafından okunabilir varlık kataloğu (asset catalog) oluşturuldu.

## How I verified it

Doğrulama için Python ve Pillow kullanılarak JSON ayrıştırma, dosya yollarının varlığı, boyutlar, alfa kanalı sınıflandırmaları ve şema alanları test edildi:

```powershell
python -c "
import json, os
from PIL import Image

manifest_path = 'assets/asset_manifest.json'
assert os.path.exists(manifest_path), 'asset_manifest.json not found'

with open(manifest_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

print('JSON parses successfully. Total entries:', len(data))

expected_assets = {
    'assets/visual-concepts/farm-world-style-anchor-v1.png': {'w': 1672, 'h': 941, 'alpha': False},
    'assets/visual-concepts/pilot/character-youthful-scythe-poses-v1.png': {'w': 1448, 'h': 1086, 'alpha': True},
    'assets/visual-concepts/pilot/crop-cereal-early-v1.png': {'w': 1254, 'h': 1254, 'alpha': False},
    'assets/visual-concepts/pilot/crop-cereal-mid-v1.png': {'w': 1254, 'h': 1254, 'alpha': False},
    'assets/visual-concepts/pilot/crop-maize-mature-v1.png': {'w': 1254, 'h': 1254, 'alpha': False},
    'assets/visual-concepts/pilot/crop-wheat-mature-v1.png': {'w': 1254, 'h': 1254, 'alpha': False},
    'assets/visual-concepts/pilot/vehicle-mini-mower-v1.png': {'w': 1536, 'h': 1024, 'alpha': True},
    'assets/visual-concepts/pilot/vehicle-starter-grain-truck-v1.png': {'w': 1536, 'h': 1024, 'alpha': True},
    'assets/visual-concepts/pilot/worker-employee-turnaround-v1.png': {'w': 1448, 'h': 1086, 'alpha': True}
}

required_fields = [
    'asset_id', 'name', 'asset_type', 'file_path', 'format',
    'dimensions_px', 'alpha', 'pivot', 'atlas', 'animation',
    'style_reference', 'prompt', 'locale_text_keys', 'status'
]

seen_paths = set()
for item in data:
    for field in required_fields:
        assert field in item, 'Missing field: ' + field
    
    path = item['file_path']
    assert path in expected_assets, 'Unexpected path: ' + path
    seen_paths.add(path)
    
    assert os.path.exists(path), 'File not found: ' + path
    im = Image.open(path)
    w, h = im.size
    has_alpha = im.mode in ('RGBA', 'LA') or (im.mode == 'P' and 'transparency' in im.info)
    
    expected = expected_assets[path]
    assert w == expected['w'] and h == expected['h'], 'Dimension mismatch for ' + path
    assert item['dimensions_px']['width'] == w and item['dimensions_px']['height'] == h, 'Manifest dimension mismatch for ' + path
    assert has_alpha == expected['alpha'], 'Alpha mismatch for ' + path
    assert item['alpha'] == has_alpha, 'Manifest alpha mismatch for ' + path
    assert item['format'] == 'png', 'Format mismatch for ' + path
    assert item['pivot'] is None, 'Pivot must be null for ' + path
    assert item['atlas'] is None, 'Atlas must be null for ' + path
    assert item['animation'] is None, 'Animation must be null for ' + path
    assert item['locale_text_keys'] == [], 'locale_text_keys must be [] for ' + path
    assert item['status'] == 'concept_awaiting_user_review', 'Status must be concept_awaiting_user_review for ' + path
    
    assert isinstance(item['prompt'], dict), 'Prompt must be dict for ' + path
    assert 'text' in item['prompt'] and 'type' in item['prompt'] and 'is_exact' in item['prompt']
    
    if path == 'assets/visual-concepts/farm-world-style-anchor-v1.png':
        assert item['style_reference'] is None
        assert item['prompt']['type'] == 'prompt_summary'
    elif 'crop' in path or 'character' in path:
        assert item['style_reference'] == 'assets/visual-concepts/farm-world-style-anchor-v1.png'
        assert item['prompt']['type'] == 'prompt_summary'
    else:
        assert item['style_reference'] == 'assets/visual-concepts/farm-world-style-anchor-v1.png'
        assert item['prompt']['type'] == 'exact_prompt'

assert len(seen_paths) == len(expected_assets), 'Not all expected assets cataloged'
print('ALL CHECKS PASSED!')
"
```

**Çıktı:**
```
JSON parses successfully. Total entries: 9
ALL CHECKS PASSED!
```

Ayrıca Flutter çalışma alanının sağlığı ve statik analizi doğrulandı:
```powershell
flutter analyze
```
**Çıktı:**
```
Analyzing farm world...                                         
No issues found! (ran in 18.9s)
```

## Notes

- **Şema Alanları:** Belirtilen 14 alan (`asset_id`, `name`, `asset_type`, `file_path`, `format`, `dimensions_px`, `alpha`, `pivot`, `atlas`, `animation`, `style_reference`, `prompt`, `locale_text_keys`, `status`) eksiksiz korundu.
- **Teknik Alanlar:** Henüz atlas veya çalışma zamanı sprite'ı olmadıklarından `pivot`, `atlas` ve `animation` alanları `null` olarak tanımlandı.
- **Durum:** Stil referansı ve tüm pilot görseller için durum `"concept_awaiting_user_review"` olarak ayarlandı; hiçbir görsel onaylı veya üretime hazır olarak işaretlenmedi.
- **Prompt Ayrımı:** [`assets/visual-concepts/pilot/manifest.md`](file:///D:/github/farm%20world/assets/visual-concepts/pilot/manifest.md) belgesindeki ayrım uyarınca ilk 6 öğe `"prompt_summary"` (`is_exact: false`), 3 yeni araç/işçi öğesi ise `"exact_prompt"` (`is_exact: true`) olarak yapılandırıldı; kaynak metinler aynen aktarıldı.
- **Yazı Anahtarları:** Görsellere gömülü metin bulunmadığından `locale_text_keys: []` olarak boş liste bırakıldı.
- **Dosya Sahipliği:** Yalnızca [`assets/asset_manifest.json`](file:///D:/github/farm%20world/assets/asset_manifest.json) dosyası oluşturuldu; çalışma alanındaki başka hiçbir dosyaya dokunulmadı ve harici test dosyası oluşturulmadı.
