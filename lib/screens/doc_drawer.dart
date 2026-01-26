import 'package:flutter/material.dart';

import '../models/doc_manifest.dart';

class DocDrawer extends StatelessWidget {
  final List<DocManifestItem> manifest;
  final Function(DocManifestItem) onItemSelected;
  final DocManifestItem? selectedItem;

  const DocDrawer({
    super.key,
    required this.manifest,
    required this.onItemSelected,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 2.0,
              left: 15.0,
              bottom: 17.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image(
                  width: 90,
                  height: 90,
                  image: AssetImage('assets/docs/images/gs_ai_logo_circle.png'),
                ),
                SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GenericSuite',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Documentation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 5.0, left: 5.0, bottom: 5.0),
              shrinkWrap: true,
              children: manifest
                  .where((item) => item.source == 'nav')
                  .map((item) => _buildItem(item, context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(DocManifestItem item, BuildContext context,
      [int depth = 0]) {
    if (item.type == 'section') {
      return ExpansionTile(
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16 - (depth * 1.0), // Slightly smaller for deeper levels
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16.0),
        children: item.children
                ?.map((child) => _buildItem(child, context, depth + 1))
                .toList() ??
            [],
      );
    } else {
      final isSelected = selectedItem == item;
      return ListTile(
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        contentPadding:
            EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16.0),
        title: Text(item.title),
        onTap: () {
          onItemSelected(item);
          Navigator.pop(context); // Close drawer
        },
      );
    }
  }
}
