import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:packer/features/views/meter_reading/providers/meter_reading_provider.dart';
import 'package:packer/features/views/meter_reading/screens/meter_reading_screen.dart';
import 'package:provider/provider.dart';

/// Smallest valid PNG, so the preview state can render a real file.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842'
    'iQAAAABJRU5ErkJggg==';

Future<void> pumpAt(
  WidgetTester tester,
  Size size, {
  MeterReadingProvider? provider,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider ?? MeterReadingProvider(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (_, __) => const MaterialApp(home: MeterReadingScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Guards a past overflow: the capture box's contents scale off the width
  // factor, so a short, wide viewport must not clip them.
  const sizes = <String, Size>{
    'iPhone SE 320x568': Size(320, 568),
    'small android 360x640': Size(360, 640),
    'iPhone 375x812': Size(375, 812),
    'tablet 800x1280': Size(800, 1280),
    'landscape 800x600': Size(800, 600),
  };

  sizes.forEach((name, size) {
    testWidgets('lays out without overflow at $name', (tester) async {
      await pumpAt(tester, size);
      expect(find.text('Submit Reading'), findsOneWidget);
      final error = tester.takeException();
      expect(error, isNull, reason: '$name -> $error');
    });
  });

  testWidgets('starts on the empty capture state', (tester) async {
    await pumpAt(tester, const Size(375, 812));

    expect(find.text('Tap to capture meter photo'), findsOneWidget);
    expect(find.text('Meter photo'), findsOneWidget);
    expect(find.text('Current reading'), findsOneWidget);
    expect(find.text('units'), findsOneWidget);
    // Both steps still show their number, neither is ticked.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('entering units ticks step 2', (tester) async {
    await pumpAt(tester, const Size(375, 812));

    await tester.enterText(find.byType(TextFormField), '1234.5');
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNothing); // became a check
    expect(find.text('1'), findsOneWidget); // photo still missing
    expect(tester.takeException(), isNull);
  });

  testWidgets('submitting empty shows the units error', (tester) async {
    await pumpAt(tester, const Size(375, 812));

    await tester.tap(find.text('Submit Reading'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter the current meter units'), findsOneWidget);
  });

  testWidgets('non-numeric units are rejected', (tester) async {
    await pumpAt(tester, const Size(375, 812));

    // The formatter strips letters, so a lone '.' stands in for junk input.
    await tester.enterText(find.byType(TextFormField), '.');
    await tester.tap(find.text('Submit Reading'));
    await tester.pumpAndSettle();

    expect(find.text('Units must be a number'), findsOneWidget);
  });

  testWidgets('a captured photo shows the preview and ticks step 1',
      (tester) async {
    final file = File('${Directory.systemTemp.path}/meter_test.png')
      ..writeAsBytesSync(base64Decode(_pngBase64));
    addTearDown(() => file.deleteSync());

    final provider = MeterReadingProvider()..setImage(XFile(file.path));
    await pumpAt(tester, const Size(375, 812), provider: provider);

    expect(find.text('Tap to capture meter photo'), findsNothing);
    expect(find.text('Retake'), findsOneWidget);
    expect(find.text('Photo captured'), findsOneWidget);
    expect(find.text('1'), findsNothing); // step 1 ticked
    expect(tester.takeException(), isNull);
  });
}
