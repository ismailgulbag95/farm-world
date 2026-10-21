# Farm World

Farm World is a mobile-first farm management game built with Flutter and Flame. A new session opens with a short, playable woodcutting shift: drive through the South Forest, cut trees, collect logs and deliver the first load. A letter then brings the young woodcutter back to the inherited Akpınar farm, its land and its starter equipment. From there the game continues on a seed-based forest-and-farmland world made of 27×27 chunks. Each 640 m chunk makes the map 17.28 km wide and high; visible chunks are generated as the player explores.

## World map prototype

- Explore within the finite map by dragging and pinching. Search by world coordinates to move to another location inside its bounds.
- Select generated agricultural parcels to inspect crop type, area, soil fertility and price; purchase land with ÇK.
- Build a costed, persistent logistics corridor between two owned parcels.
- Toggle field, route, infrastructure and fertility layers; use the distance tool to inspect remote locations.
- Visible map chunks are generated on demand; unmodified terrain and parcel offers are reproducible from the saved world seed instead of being stored as a giant map.

See [the world-map prototype notes](docs/procedural-world-map-prototype.md) for generation rules and the current feature boundary.

## Existing farm-management gameplay

- Pan the farm map with one finger and zoom with two fingers. Tap fields and buildings to inspect them; use **Harita** to return to the full-farm view.
- Plant wheat or maize on the starter field, follow the six-minute prototype growth cycle, harvest, and complete the first trade.
- Track soil condition and yield. Research T02 to enable automatic soil care without creating debt.
- Open the 30-node research tree across nine branches. Each node shows its prerequisites, production or delivery evidence, credit cost, status, and effect.
- Use the **Tarlalar** and **Filo** navigation to inspect farm operations, and save progress locally with automatic background saves.
- Switch between English, Turkish, Spanish, and German from the farm HUD.

Opening economy values are prototype settings documented in [the crop loop decision](docs/decisions/2026-10-11-opening-crop-prototype.md) and [the first diversity decision](docs/decisions/2026-10-11-first-diversity-prototype.md); they are not final balance approval.

## Run on a connected device

Install Flutter and the Android platform tools, connect an authorized Android phone over USB, and run:

```powershell
flutter pub get
flutter devices
flutter run -d <device-id>
```

To build a local Android review package:

```powershell
flutter build apk --debug
```

## Quality checks

```powershell
flutter analyze
flutter test --no-pub
```

## Store build preparation

- Android release signing reads `android/key.properties`. Start with [the example](android/key.properties.example), keep the real key and passwords out of source control, and use the same permanent application ID for every Play Store update.
- A release AAB built without `android/key.properties` is unsigned. Build it with the private Play upload key before upload.
- The current Android and iOS bundle identifiers are Flutter template values. Choose a unique permanent identifier before creating store records or signing publication builds.
- iOS archives and App Store upload require macOS with Xcode. The iOS launch art and app icon catalog are included in this project.
- The store icon sources and generated platform variants are listed in [the asset manifest](assets/asset_manifest.json).

## Design and asset records

Product and visual requirements live in `docs/`. Generated artwork, source prompts, dimensions, integration status, and platform variants are recorded in `assets/asset_manifest.json` and `assets/visual-concepts/pilot/manifest.md`.
