import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

import 'package:image_picker/image_picker.dart';

class DocumentScannerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const DocumentScannerScreen({super.key, required this.cameras});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<File> _capturedImages = [];
  bool _isFlashOn = false;
  bool _isProcessing = false;
  double _borderWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.cameras.first,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      setState(() => _isProcessing = true);

      // Capture the image
      final XFile picture = await _controller.takePicture();
      final File imageFile = File(picture.path);

      // Enhance the image to look like a scanned document
      final enhancedImage = await _enhanceImage(imageFile);

      setState(() {
        _capturedImages.add(enhancedImage);
        _borderWidth = 2.0; // Show visual feedback
      });

      // Reset border animation after delay
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _borderWidth = 0.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<File> _enhanceImage(File originalImage) async {
    // Read the image file
    final bytes = await originalImage.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Convert to grayscale for document-like appearance
    image = img.grayscale(image);

    // Increase contrast
    image = img.contrast(image, contrast: 150);

    // Apply edge enhancement
    image = img.convolution(
      image,
      filter: [
        -1, -1, -1,
        -1, 9, -1,
        -1, -1, -1,
      ],
      div: 3,
    );
    // Add a white border to simulate paper
    image = img.copyExpandCanvas(
      image,
      newWidth: image.width + 40,  // Add 20px padding left + right
      newHeight: image.height + 40, // Add 20px padding top + bottom
      position: img.ExpandCanvasPosition.center,
      backgroundColor: img.ColorRgb8(255, 255, 255), // White border
    );


    // Save the enhanced image
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newFile = File(path);
    await newFile.writeAsBytes(img.encodeJpg(image));

    return newFile;
  }

  Future<void> _compileToPdf() async {
    if (_capturedImages.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final pdf = pw.Document();

      for (final imageFile in _capturedImages) {
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Save the PDF
      final output = await getTemporaryDirectory();
      final pdfPath = '${output.path}/scanned_document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      // Return the PDF path to previous screen
      if (!mounted) return;
      Navigator.pop(context, file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating PDF: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleFlash() async {
    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _controller.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling flash: $e')),
      );
    }
  }

  Future<void> _addFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() => _isProcessing = true);
        final enhancedImage = await _enhanceImage(File(pickedFile.path));
        setState(() => _capturedImages.add(enhancedImage));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _compileToPdf,
            ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controller);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (_capturedImages.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: index == _capturedImages.length - 1 ? _borderWidth : 0,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            Image.file(
                              _capturedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  'Page ${index + 1}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'flash',
                onPressed: _toggleFlash,
                backgroundColor: Colors.black54,
                child: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                heroTag: 'capture',
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 36,
                ),
              ),
              FloatingActionButton(
                heroTag: 'gallery',
                onPressed: _addFromGallery,
                backgroundColor: Colors.black54,
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}