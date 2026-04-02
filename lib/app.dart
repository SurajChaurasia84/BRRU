import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

class PoemsApp extends StatelessWidget {
  const PoemsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Visabrru',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A1F33),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF0A1F33),
          secondary: const Color(0xFF123A5A),
          surface: const Color(0xFFF7F9FB),
          inversePrimary: const Color(0xFF0A1F33),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1F33),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0A1F33),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  bool get _supportsFirebase =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<FirebaseApp> _initializeFirebase() {
    return Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsFirebase) {
      return const UnsupportedPlatformScreen(appName: 'Visabrru');
    }

    return FutureBuilder<FirebaseApp>(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScreen(message: 'Loading poems...');
        }

        if (snapshot.hasError) {
          return ErrorScreen(message: 'Firebase init failed: ${snapshot.error}');
        }

        return const MyHomePage(title: 'Visabrru');
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String _playStoreLink =
      'https://play.google.com/store/apps/details?id=com.visabrru.poems';
  static const String _facebookLink =
      'https://www.facebook.com/profile.php?id=61584908841134';
  static const String _whatsAppLink =
      'https://whatsapp.com/channel/0029VbBh69LKQuJIZWv5xV0o';
  static const String _youtubeChannelLink =
      'https://youtube.com/@boysenberrysm?si=296VxdjDoCqIu3j7';
  static const String _emailAddress = 'rupeshraybhar516@gmail.com';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sharePending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _poemsStream() {
    return FirebaseFirestore.instance
        .collection('poems')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  Future<void> _openEmailClient() async {
    final emailUri = Uri(scheme: 'mailto', path: _emailAddress);

    try {
      if (await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Ignore and try the fallbacks below.
    }

    try {
      if (await launchUrl(emailUri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {
      // Ignore and try the web fallback.
    }

    final webEmailUri = Uri(
      scheme: 'https',
      host: 'mail.google.com',
      path: '/mail/',
      queryParameters: {'view': 'cm', 'fs': '1', 'to': _emailAddress},
    );

    try {
      if (
          await launchUrl(
            webEmailUri,
            mode: LaunchMode.externalApplication,
          ) ||
          await launchUrl(webEmailUri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {
      // Fall through to toast below.
    }

    Fluttertoast.showToast(msg: 'Not available');
  }

  Future<void> _shareApp() async {
    await Share.share('Check out Visabrru on the Play Store: $_playStoreLink');
  }

  Future<void> _rateApp() async {
    await _openExternalLink(_playStoreLink);
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Fluttertoast.showToast(msg: 'Not available');
      return;
    }

    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Ignore and try the platform default fallback.
    }

    try {
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        return;
      }
    } catch (_) {
      // Fall through to toast below.
    }

    Fluttertoast.showToast(msg: 'Not available');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (isOpened) async {
        if (!isOpened && _sharePending) {
          _sharePending = false;
          await Future<void>.delayed(const Duration(milliseconds: 150));
          await _shareApp();
        }
      },
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A1F33),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _poemsStream(),
                  builder: (context, snapshot) {
                    final poemCount = snapshot.data?.docs.length ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Visabrru Poetry',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Available $poemCount poems',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white54, thickness: 1),
              ListTile(
                tileColor: const Color(0xFF123A5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: _closeDrawer,
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.white),
                title: const Text(
                  'Privacy Policy',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _closeDrawer();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rate, color: Colors.white),
                title: const Text(
                  'Rate Us',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  _closeDrawer();
                  await Future<void>.delayed(const Duration(milliseconds: 150));
                  await _rateApp();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text(
                  'Share App',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _sharePending = true;
                  _closeDrawer();
                },
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Connect with us',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.facebook, color: Colors.white),
                      title: const Text(
                        'Facebook',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        _closeDrawer();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 150),
                        );
                        await _openExternalLink(_facebookLink);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SvgPicture.asset(
                        'assets/youtube.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: const Text(
                        'YouTube',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        _closeDrawer();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 150),
                        );
                        await _openExternalLink(_youtubeChannelLink);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SvgPicture.asset(
                        'assets/whatsapp.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      title: const Text(
                        'WhatsApp Channel',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        _closeDrawer();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 150),
                        );
                        await _openExternalLink(_whatsAppLink);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email, color: Colors.white),
                      title: const Text(
                        'Email',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onTap: () async {
                        _closeDrawer();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 150),
                        );
                        await _openEmailClient();
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search poems, author, language',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _poemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingBody(message: 'Fetching poems...');
                }

                if (snapshot.hasError) {
                  return const ErrorBody(
                    message: 'Unable to load poems right now.',
                  );
                }

                final docs = snapshot.data?.docs ?? const [];
                final poems = docs
                    .map(Poem.fromDocument)
                    .where(_matchesSearch)
                    .toList();

                if (docs.isEmpty) {
                  return const EmptyBody(
                    message: 'No poems available yet. Please check back later.',
                  );
                }

                if (poems.isEmpty) {
                  return const EmptyBody(message: 'No poems match your search.');
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: poems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return PoemTile(poem: poems[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSearch(Poem poem) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final author = poem.author?.toLowerCase() ?? '';
    return poem.title.toLowerCase().contains(_searchQuery) ||
        poem.language.toLowerCase().contains(_searchQuery) ||
        author.contains(_searchQuery);
  }
}

class PoemTile extends StatelessWidget {
  const PoemTile({super.key, required this.poem});

  final Poem poem;

  Future<void> _openYoutubeLink() async {
    final link = poem.youtubeLink?.trim();
    if (link == null || link.isEmpty) {
      Fluttertoast.showToast(msg: 'Not available');
      return;
    }

    final normalizedLink = _normalizeLink(link);
    final uri = Uri.tryParse(normalizedLink);
    if (uri == null) {
      Fluttertoast.showToast(msg: 'Not available');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return;
      }
    } catch (_) {
      // Fall through to toast below.
    }

    Fluttertoast.showToast(msg: 'Not available');
  }

  String _normalizeLink(String link) {
    final trimmed = link.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }
    if (trimmed.contains('youtube.com') || trimmed.contains('youtu.be')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PoemDetailScreen(poem: poem)),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140A1F33),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF0A1F33),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poem.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Author: ${poem.author?.isNotEmpty == true ? poem.author! : 'Not available'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF405465),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F5F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      poem.language,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A1F33),
                      ),
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton.icon(
                      onPressed: _openYoutubeLink,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.play_circle_outline, size: 20),
                      label: const Text('YouTube'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PoemDetailScreen extends StatelessWidget {
  const PoemDetailScreen({super.key, required this.poem});

  final Poem poem;

  Future<void> _openYoutubeLink() async {
    final link = poem.youtubeLink?.trim();
    if (link == null || link.isEmpty) {
      Fluttertoast.showToast(msg: 'Not available');
      return;
    }

    final normalizedLink = _normalizeLink(link);
    final uri = Uri.tryParse(normalizedLink);
    if (uri == null) {
      Fluttertoast.showToast(msg: 'Not available');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return;
      }
    } catch (_) {
      // Fall through to toast below.
    }

    Fluttertoast.showToast(msg: 'Not available');
  }

  String _normalizeLink(String link) {
    final trimmed = link.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }
    if (trimmed.contains('youtube.com') || trimmed.contains('youtu.be')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(poem.title),
        actions: [
          IconButton(
            onPressed: _openYoutubeLink,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    poem.language,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A1F33),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'By: ${poem.author?.isNotEmpty == true ? poem.author! : 'Not available'}',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF405465),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140A1F33),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                poem.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.8,
                  color: const Color(0xFF1A2530),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Poem {
  const Poem({
    required this.id,
    required this.title,
    required this.language,
    required this.content,
    this.author,
    this.youtubeLink,
  });

  final String id;
  final String title;
  final String language;
  final String content;
  final String? author;
  final String? youtubeLink;

  factory Poem.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Poem(
      id: doc.id,
      title: _stringOrFallback(data['title'], 'Untitled poem'),
      language: _stringOrFallback(data['language'], 'Unknown'),
      content: _stringOrFallback(data['content'], 'Poem text not available.'),
      author: _nullableString(data['author']),
      youtubeLink: _nullableString(data['youtubeLink']),
    );
  }

  static String _stringOrFallback(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LoadingBody(message: message));
  }
}

class UnsupportedPlatformScreen extends StatelessWidget {
  const UnsupportedPlatformScreen({super.key, required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appName)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Firebase is configured for Android in this project. Run this app on Android to use poems.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class LoadingBody extends StatelessWidget {
  const LoadingBody({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class EmptyBody extends StatelessWidget {
  const EmptyBody({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class ErrorBody extends StatelessWidget {
  const ErrorBody({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visabrru')),
      body: ErrorBody(message: message),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Visabrru Privacy Policy',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Effective date: April 2, 2026',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Overview',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Visabrru is a poetry application that allows users to browse poems and open related external links such as YouTube, Facebook, WhatsApp, email, and the Google Play Store. This Privacy Policy explains what information may be processed when you use the app and how that information is handled.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Information We Collect',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Visabrru does not require users to create an account in the user app. The app displays poem data that is stored in Firebase Firestore, including fields such as title, language, author name, poem text, and optional YouTube links. The app may also process limited technical information necessary for app functionality, such as network requests, crash-related system behavior, and device-level app routing when opening external links.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'How We Use Information',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'We use the information available in the app to display poems, organize content by language and author, support search, and open related external links selected by the user. Firebase services are used to store and deliver poem content for app functionality.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'External Services and Links',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'The app may open third-party services such as YouTube, Facebook, WhatsApp, Gmail, browsers, and the Google Play Store. When you open a third-party service, that service may collect information according to its own privacy policy. Visabrru does not control third-party data practices outside the app.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Data Sharing and Sale',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'We do not sell personal information through the Visabrru user app. We may rely on service providers such as Firebase to support core app functionality. Those providers may process technical data as necessary to operate their services.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Data Retention',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Poem content remains available in our backend until it is updated or removed by the app administrator. Any information you send to us directly by email may be retained for support, communication, or record-keeping purposes as reasonably necessary.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Children\'s Privacy',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Visabrru is not intended to knowingly collect personal information from children through the user app. If you believe information relating to a child has been provided to us inappropriately, please contact us so we can review and take suitable action.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Your Choices',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'You may choose whether to open external links from within the app. You may also contact us if you want to request correction or removal of specific poem-related information that you believe is inaccurate or inappropriate.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Policy Updates',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'We may update this Privacy Policy from time to time to reflect changes in the app, legal requirements, or operational needs. Updated versions will be reflected inside the app with a revised effective date where applicable.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Contact Us',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'If you have any privacy-related questions or requests, please contact us at rupeshraybhar516@gmail.com.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
