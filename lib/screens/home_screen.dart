import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../widgets/balance_card.dart';
import '../widgets/uploaded_files_graph.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BalanceCard(),
          const SizedBox(height: 16),
          const Text("Your Uploaded Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const UploadedFilesGraph(),
          const SizedBox(height: 16),
          const Center(child: Text("No uploaded/bought files yet.")),
        ],
      ),
    );
  }
}
