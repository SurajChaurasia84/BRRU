import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'main.dart'; // Yahan aapka PoemDetailScreen import karo
import 'poem_model.dart'; // Yahan aapka Poem model import karo

class PoemDetailLoaderScreen extends StatefulWidget {
  final Poem poem;
  const PoemDetailLoaderScreen({super.key, required this.poem});

  @override
  State<PoemDetailLoaderScreen> createState() => _PoemDetailLoaderScreenState();
}

class _PoemDetailLoaderScreenState extends State<PoemDetailLoaderScreen> {
  bool _navigated = false; // prevent double navigation

  @override
  void initState() {
    super.initState();
    _showInterstitial();
  }

  void _showInterstitial() {
    // Timeout fail-safe: 3 sec me agar ad load na ho, screen khol do
    Future.delayed(const Duration(seconds: 3), () {
      if (!_navigated) _openPoemScreen();
    });

    UnityAds.showVideoAd(
      placementId: 'Interstial_Android', // your interstitial placement id
      onStart: (placementId) {
        if (kDebugMode) print('Interstitial started');
      },
      onComplete: (placementId) {
        if (!_navigated) _openPoemScreen();
      },
      onFailed: (placementId, error, message) {
        if (!_navigated) _openPoemScreen();
      },
    );
  }

  void _openPoemScreen() {
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PoemDetailScreen(poem: widget.poem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading Poem...'),
          ],
        ),
      ),
    );
  }
}