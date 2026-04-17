import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/alchemist_config.dart';
import 'helpers/test_font_loader.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  debugDisableShadows = true;
  await loadTestFonts();
  return AlchemistConfig.runWithConfig(
    config: projectAlchemistConfig,
    run: testMain,
  );
}
