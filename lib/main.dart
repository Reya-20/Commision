import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'theme/app_colors.dart';
import 'screens/document_scanner_screen.dart'; // ✅ Import the scanner screen

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Commission App',
      home: MainScreen(cameras: cameras),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainScreen({super.key, required this.cameras});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey),
              child: Text('Menu', style: TextStyle(color: Colors.white)),
            ),
            ListTile(title: Text('Home')),
            ListTile(title: Text('Wallet Top Up')),
            ListTile(title: Text('Account Setting')),
            ListTile(title: Text('Logout')),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Search'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blueGrey[900]),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueGrey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet, size: 32, color: Colors.white),
                    SizedBox(height: 8),
                    Text('Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.blueGrey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [
                Tab(text: 'Home'),
                Tab(text: 'Marketplace'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Center(child: Text('Uploaded/Bought Files + Graph Placeholder')),
                Center(child: Text('Marketplace Files Placeholder')),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isExpanded) ...[
            FloatingActionButton(
              heroTag: 'upload',
              onPressed: () {
                setState(() => _isExpanded = false);
                // TODO: Implement upload functionality
              },
              backgroundColor: Colors.blueGrey[700],
              child: const Icon(Icons.file_upload),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'camera',
              onPressed: () {
                setState(() => _isExpanded = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DocumentScannerScreen(cameras: widget.cameras), // ✅ Fixed navigation
                  ),
                );
              },
              backgroundColor: Colors.blueGrey[700],
              child: const Icon(Icons.camera_alt),
            ),
            const SizedBox(height: 10),
          ],
          FloatingActionButton(
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            backgroundColor: Colors.blueGrey,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const Icon(Icons.add),
              secondChild: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
