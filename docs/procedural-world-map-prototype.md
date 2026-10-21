# Procedural World Map Prototype

## Goal

This vertical slice turns the former fixed 900×620 management view into a mobile map that can be explored by dragging and zooming inside a finite world. It uses a fictional, deterministic world. The visual language takes cues from [Scribble Maps' agriculture maps](https://www.scribblemaps.com/tr/sektorler/tar%C4%B1m): colored field shapes, separate infrastructure/route layers, field details and map measurement tools, rendered over the game's illustrated forest terrain.

## World generation

- `ProceduralFarmWorld` derives each 640 m chunk from the save's `worldSeed`. Only visible chunks are generated on demand and retained in a bounded cache.
- The map contains 27×27 chunks: 17.28 km on each axis, from approximately −8,320 m to 8,960 m. Panning or searching within those bounds generates the same terrain and offers for that seed and coordinate.
- Every 8×8 chunk district gets a deterministic agricultural hub. Parcel offers become denser and more fertile near hubs, while the space between hubs remains forest with occasional isolated offers.
- The current settlement generation places road-connected villages across the map in addition to the district hubs. Nearby parcel clusters are denser and use tighter spacing; settlement clearances keep their buildings separate from fields.
- A parcel offer has a stable ID, crop/pasture type, area, fertility and price. The price includes a local-density premium; generated remote parcels usually cost less.
- Forest canopies, occasional ponds, villages, mills, water points, timber yards and long-distance dirt-road corridors are decorative map features. They are generated from the same seed.

## Opening and landmarks

- The opening story introduces Akpınar, the inherited starter field and Ayla Demirsoy. The guided tutorial validates each farm operation on that field, then guides the player through storage, the first delivery, equipment and farm management.
- Farmstead buildings, settlement houses, town halls and market stalls are ThreeJS models. Windmill rotors and market pennants animate while visible; house locations stay deterministic as the camera moves.

## Player actions

- Drag with one finger to pan; pinch to zoom; use the map buttons for zoom and recenter.
- Open coordinate search to move to an X/Y location inside the map bounds. Coordinates are in meters.
- Tap a visible parcel for its area, crop type, soil score and price. Buy it if the current ÇK balance covers the full price.
- Choose **Hat kur**, tap an owned starting parcel and then another owned parcel. The quote shows straight-line distance and construction cost before charging the player.
- Use **Mesafe ölç** to measure between two map points.
- Use **Katmanlar** to toggle parcel boundaries, route/road markings, infrastructure symbols and the fertility heat colors. The legend distinguishes crop type, offered parcels and owned parcels.

## Presentation levels

- At overview zoom, field offers are simplified and district names, forest masses and long-distance roads carry the map.
- At working zoom, available and owned field polygons show crop colors, boundaries, furrows and selection states.
- At close zoom, plots gain fence/gate detail, crop labels, resource and facility symbols, and selected-parcel information.
- Purchased logistics links use a thick road underlay, a high-contrast golden route and a truck marker so they remain distinct from the generated road network.

## Saved state

`OpeningSessionState` stores the world seed, purchased parcel IDs, route endpoints, route coordinates and route cost. The deterministic generator reconstructs all unmodified terrain and unsold parcel offers after restart; the save only grows with player changes.

## Prototype boundary

This prototype validates world navigation, parcel search/purchase, map-layer readability and construction of persistent long-distance corridors. The corridor is currently a world-map connection with a map marker; assigning live cargo schedules and simulating vehicles on that corridor is a later logistics integration step. Generated crop labels are parcel identity/land-use hints and do not yet create a separate crop-growth simulation for every world parcel.
