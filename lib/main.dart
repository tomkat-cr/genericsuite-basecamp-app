import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'models/doc_manifest.dart';
import 'screens/doc_viewer_screen.dart';
import 'services/doc_service.dart';
import 'services/utilities.dart';

void main() {
  runApp(const GsDoc());
}

class GsDoc extends StatelessWidget {
  const GsDoc({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DocService()),
      ],
      child: MaterialApp(
        title: 'GenericSuite Docs',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0052CC), // GenericSuite Blue-ish
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0052CC),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        themeMode: ThemeMode.system,
        home: const AppHome(),
      ),
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  DocManifestItem? _currentItem;
  bool _initialized = false;
  String lang = '';

  @override
  void initState() {
    super.initState();
    lang = getLangForApp();
    _init();
  }

  Future<void> _init() async {
    final docService = context.read<DocService>();
    await docService.loadManifest();

    if (mounted) {
      setState(() {
        _currentItem = docService.getFirstPage(lang);
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DocViewerScreen(
      manifest: context.read<DocService>().manifest,
      initialItem: _currentItem,
      onPageChanged: (item) {
        setState(() {
          _currentItem = item;
        });
      },
      onLangChanged: (newLang) {
        setState(() {
          lang = newLang;
          _currentItem = _currentItem!.copyWithLang(lang);
        });
      },
      lang: lang,
    );
  }
}
