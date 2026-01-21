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
      width: 280,
      child: Column(
        children: [
          DrawerHeader(
            // padding: const EdgeInsets.only(
            //     top: 5.0, bottom: 5.0, left: 5.0, right: 5.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Container(
              alignment: Alignment.topLeft,
              child: const Row(
                // mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    width: 70,
                    height: 70,
                    image:
                        AssetImage('assets/docs/images/gs_ai_logo_circle.png'),
                  ),
                  Text(' '),
                  Column(
                    children: [
                      Text(
                        'GenericSuite',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        'Documentation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
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
