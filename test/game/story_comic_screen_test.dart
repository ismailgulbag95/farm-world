import 'package:farm_world/game/ui/story_comic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('comic tells the six story beats with short captions', (
    tester,
  ) async {
    final captions = [
      'Dedenin mektubu seni çağırıyor.',
      'Eski traktör yeniden hazır.',
      'Toprağı birlikte uyandıralım.',
      'Ata tohumlarını ek.',
      'İlk hasat, senin emeğin.',
      'Bu çiftlik artık senin.',
    ];
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StoryComicScreen(
          canDismiss: false,
          onComplete: () => completed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    for (var index = 0; index < captions.length; index++) {
      expect(find.text(captions[index]), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      if (index < captions.length - 1) {
        await tester.tap(find.text('Devam'));
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.text('Başla'));
    expect(completed, isTrue);
  });

  testWidgets('image-first comic fits phone, landscape, and tablet layouts', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(360, 640),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(home: StoryComicScreen(onComplete: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget, reason: '$size');
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
