import 'package:flutter/widgets.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UnityAds.init(
    gameId: '6080439', 
    testMode: false, // false for production
    onComplete: () {
    if (kDebugMode) {
      print('Unity Ads Initialized');
    }
  },

  onFailed: (error, message) {
    if (kDebugMode) {
      print('Unity Ads Init Failed: $error $message');
    }
  },
  );

  runApp(const PoemsApp());
}
