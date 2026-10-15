import 'package:flutter/material.dart';

import '../domain/procedural_farm_world.dart';

class FarmMapRegionInfoCard extends StatelessWidget {
  const FarmMapRegionInfoCard({
    super.key,
    required this.region,
    required this.onClose,
  });

  final WorldMapRegion region;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final crop = switch (region.favoredCrop) {
      WorldCropType.grain => ('Tahıl', Icons.grass_rounded),
      WorldCropType.oilseed => ('Yağlı tohum', Icons.local_florist_rounded),
      WorldCropType.vegetable => ('Sebze', Icons.eco_rounded),
      WorldCropType.pasture => ('Mera', Icons.pets_rounded),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F2DC),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFCBBF91), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40192E1D),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(region.color).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.terrain_rounded,
                  color: Color(0xFF244C35),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  region.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF18392A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                tooltip: 'Kapat',
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _RegionTag(icon: crop.$2, label: 'Ürün odağı · ${crop.$1}'),
              _RegionTag(
                icon: Icons.layers_rounded,
                label: region.soilDescription,
              ),
              _RegionTag(
                icon: Icons.water_drop_rounded,
                label: region.waterDescription,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegionTag extends StatelessWidget {
  const _RegionTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE7EBD5),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF385E3B)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF36523A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
