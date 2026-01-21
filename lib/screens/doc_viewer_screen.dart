import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../models/doc_manifest.dart';
import '../services/utilities.dart';
import 'doc_drawer.dart';

const debug = false;
const contentLoadError = '# Error\nCould not load content:';

Future<void> launchURLBrowser(String url) async {
  // Parse the URL string into a Uri object
  final Uri uri = Uri.parse(url);

  // Check if the URL can be launched before attempting to do so
  if (await canLaunchUrl(uri)) {
    // Launch the URL in the external application (default browser)
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } else {
    // Handle the case where the URL cannot be launched
    throw 'Could not launch $url';
  }
}

class DocViewerScreen extends StatefulWidget {
  final DocManifestItem? initialItem;
  final List<DocManifestItem> manifest;
  final Function(DocManifestItem) onPageChanged;

  const DocViewerScreen({
    super.key,
    required this.manifest,
    this.initialItem,
    required this.onPageChanged,
  });

  @override
  State<DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<DocViewerScreen> {
  String? _markdownContent;
  String? _currentPath;
  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _anchorKeys = {};

  @override
  void didUpdateWidget(DocViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItem != oldWidget.initialItem) {
      _loadContent();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getPath(dynamic path, [String basePath = '']) {
    path = path.toString();
    if (basePath.isEmpty) {
      return path;
    }
    path = path.startsWith('../')
        ? '${_getParentPath(basePath)}/${path.substring(3)}'
        : path;
    path = path.startsWith('./') ? '$basePath/${path.substring(2)}' : path;
    return path;
  }

  String _getParentPath(dynamic path) {
    path = path.toString();
    if (path.isEmpty) {
      return '';
    }
    path = path.split('/').length > 1
        ? path.split('/').sublist(0, path.split('/').length - 1).join('/')
        : '';
    return path;
  }

  Future<dynamic> _getFileContent(dynamic path, [String basePath = '']) async {
    if (debug) {
      logDebug(
          'DocViewerScreen | _getFileContent | path: $path | basePath: $basePath');
    }
    basePath = basePath.isEmpty ? '' : '$basePath/';
    dynamic content;
    try {
      path = _getPath(path, basePath);
      content = await rootBundle.loadString('assets/docs/$path');
    } catch (e) {
      logError('$contentLoadError File "$path". Error: $e \n[DVS-E-010]');
    }
    return content;
  }

  Future<void> _loadContent() async {
    if (widget.initialItem?.path == null) {
      setState(() {
        _markdownContent = '# Welcome\nSelect a page from the menu.';
        _currentPath = null;
        _isLoading = false;
        if (debug) {
          logDebug('DocViewerScreen | initialItem: ${widget.initialItem}');
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _anchorKeys.clear();
    });

    try {
      final content = await _getFileContent(widget.initialItem!.path);
      setState(() {
        _markdownContent = content ??
            '$contentLoadError File: ${widget.initialItem!.path} \n[DVS-E-020]';
        _currentPath =
            content != null ? _getPath(widget.initialItem!.path) : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _markdownContent =
            '$contentLoadError File: ${widget.initialItem!.path}. Error: $e \n[DVS-E-030]';
        _currentPath = null;
        _isLoading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Search for anchors in markdown content
    (_markdownContent ?? '').split('\n').forEach((line) {
      if (line.startsWith('#')) {
        String anchor = line.split('#').last.trim();
        anchor = anchor.replaceAll(' ', '-').toLowerCase();
        anchor =
            anchor.replaceAll('?', '').replaceAll('(', '').replaceAll(')', '');
        // anchor = '#$anchor';
        if (debug) {
          logDebug('DocViewerScreen | anchor: $anchor');
        }
        _anchorKeys[anchor] = GlobalKey();
      }
    });
    if (debug) {
      logDebug('DocViewerScreen | _anchorKeys: ${_anchorKeys.toString()}');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem?.title ?? 'Documentation'),
      ),
      drawer: DocDrawer(
        manifest: widget.manifest,
        selectedItem: widget.initialItem,
        onItemSelected: widget.onPageChanged,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Markdown(
              controller: _scrollController,
              data: _markdownContent ?? '',
              selectable: true,
              imageDirectory:
                  'https://raw.githubusercontent.com/tomkat-cr/genericsuite-basecamp/main/docs/', // Basic fallback for external images if not in assets? Or use assets?

              // TODO: add imageDirectory for local assets
              // For local assets, we need a custom image builder or ensure paths are relative to asset root?
              // flutter_markdown handles asset images if resource starts with resource: or similar?
              // Actually, simplified: local assets are best referenced by proper asset path.
              // But converted files might have relative paths like ../images/img.png.
              // We might need an imageBuilder to resolve these.

              // TODO: fix the anchors link
              // Let's assume standard markdown links for now.
              // builders: {
              //   'h1': HeaderBuilder(_anchorKeys),
              //   'h2': HeaderBuilder(_anchorKeys),
              //   'h3': HeaderBuilder(_anchorKeys),
              //   'h4': HeaderBuilder(_anchorKeys),
              //   'h5': HeaderBuilder(_anchorKeys),
              //   'h6': HeaderBuilder(_anchorKeys),
              // },
              onTapLink: (text, href, title) async {
                if (href == null) {
                  return;
                }
                if (href.startsWith('http')) {
                  // Open external link
                  if (debug) {
                    logDebug('DocViewerScreen | href: $href');
                  }
                  try {
                    await launchURLBrowser(href);
                  } catch (e) {
                    logError('DocViewerScreen | Error: $e');
                  }
                } else if (href.startsWith('#')) {
                  // Scroll to anchor
                  final anchor = href.substring(1);
                  if (debug) {
                    logDebug('DocViewerScreen | Scrolling to anchor: $anchor');
                  }
                  final key = _anchorKeys[anchor];
                  if (key != null) {
                    if (key.currentContext != null) {
                      Scrollable.ensureVisible(
                        key.currentContext!,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      if (debug) {
                        logDebug(
                            'DocViewerScreen | Key found but context is null for'
                            ' anchor: $anchor. Widget might be disposed or off-screen.');
                      }
                    }
                  } else {
                    if (debug) {
                      logDebug(
                          'DocViewerScreen | Anchor key not found for: $anchor');
                    }
                  }
                } else {
                  // Open link
                  if (debug) {
                    logDebug('DocViewerScreen | href: $href');
                    logDebug(
                        'DocViewerScreen | manifest: ${widget.manifest.toString()}');
                  }
                  dynamic item;
                  for (var element in widget.manifest) {
                    if (element.children != null) {
                      for (var child in element.children!) {
                        if (child.path == href) {
                          item = child;
                          break;
                        }
                      }
                    } else {
                      if (element.path == href) {
                        item = element;
                        break;
                      }
                    }
                  }
                  if (debug) {
                    logDebug('DocViewerScreen | FOUND item: $item');
                  }
                  if (item != null) {
                    widget.onPageChanged(item);
                  } else {
                    dynamic content = await _getFileContent(
                        href, _getParentPath(_currentPath));

                    if (content != null) {
                      // Get the title from the fist line
                      String title = content.split('\n').first;
                      title = title.split('#').last;
                      final path = _getPath(href, _getParentPath(_currentPath));
                      item = DocManifestItem.fromJson({
                        'path': path,
                        'title': title,
                        'children': null,
                        'type': 'file',
                        'source': 'calculated',
                      });
                      widget.onPageChanged(item);
                    }
                  }
                }
                if (debug) {
                  logDebug('DocViewerScreen | Link tapped: $href');
                }
              },
            ),
    );
  }
}

class HeaderBuilder extends MarkdownElementBuilder {
  final Map<String, GlobalKey> anchorKeys;

  HeaderBuilder(this.anchorKeys);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    // Simple slugification: lowercase, remove non-alphanumeric (except hyphens/spaces), replace spaces with hyphens
    // This regex allows alphanumeric, spaces, and hyphens.
    // Then we replace spaces with hyphens.
    // Note: This must match how the markdown generator creates anchors.
    // Standard python-markdown or github slugify might be slightly different.
    // We'll mimic a common one: lowercase, alphanumeric and hyphens only.
    final slug = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remove invalid chars
        .trim()
        .replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with hyphens

    final key = GlobalKey();
    anchorKeys[slug] = key;

    // We return a SizedBox which wraps the text to provide the context for the key.
    // However, simply returning Text might lose the header styling (h1, h2, etc).
    // MarkdownElementBuilder.visitElementAfter replaces the default rendering.
    // To preserve styling, we use the preferredStyle provided by flutter_markdown.
    return SizedBox(
      key: key,
      width: double.infinity,
      child: Text(
        text,
        style: preferredStyle,
      ),
    );
  }
}
