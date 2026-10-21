import 'package:flutter/material.dart';

import '../domain/debug_action_controller.dart';

class DebugSettingsButton extends StatelessWidget {
  const DebugSettingsButton({
    super.key,
    this.iconColor = const Color(0xFF557B49),
  });

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ayarlar',
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Ayarlar'),
          content: ValueListenableBuilder<bool>(
            valueListenable: DebugActionController.instance.debugModeNotifier,
            builder: (context, enabled, child) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: DebugActionController.instance.setDebugModeEnabled,
              title: const Text('Debug modu'),
              subtitle: const Text(
                'Her oyuncu işleminden önce 2 saniye bekle.',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
      icon: const Icon(Icons.settings_rounded),
      color: iconColor,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(7),
      constraints: const BoxConstraints.tightFor(width: 38, height: 40),
    );
  }
}
