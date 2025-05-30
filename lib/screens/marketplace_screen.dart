import 'package:flutter/material.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Replace with actual file count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text('File ${index + 1}'),
            subtitle: const Text('Price: 10 Coins'),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const Text('Buy'),
            ),
          ),
        );
      },
    );
  }
}
