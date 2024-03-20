import 'dart:io';
// Import for Uint8List
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String apiKey = 'REPLACE_WITH_YOUR_API_KEY'; // Replace with your API key
  final picker = ImagePicker();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Guard',
      home: GreenGuardScreen(apiKey: apiKey, picker: picker),
    );
  }
}

class GreenGuardScreen extends StatefulWidget {
  final String apiKey;
  final ImagePicker picker;

  const GreenGuardScreen({Key? key, required this.apiKey, required this.picker})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _GreenGuardScreenState createState() => _GreenGuardScreenState();
}

class _GreenGuardScreenState extends State<GreenGuardScreen> {
  String _generatedText = '';

  Future<void> _generateText(File imageFile) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-vision-pro',
        apiKey: widget.apiKey,
      );

      // Read image bytes from file
      final imageBytes = await imageFile.readAsBytes();

      // Create a http.MultipartFile object from the image bytes
      final imagePart = http.MultipartFile.fromBytes('image', imageBytes, contentType: MediaType('image', 'jpeg'));

      final response = await model.generateContent([
        Content.text(
            "Analyze the plant/tree and provide information on diseases and treatment"),
        Content('image/jpeg', imagePart as List<Part>), // Use http.MultipartFile for image data
      ]);

      setState(() {
        _generatedText = response.text!;
      });
    } catch (error) {
      // ignore: avoid_print
      print("Error generating text: $error");
      // Optionally show an error message to the user
    }
  }

  Future<void> _getImageAndGenerateText(ImageSource source) async {
    final pickedFile = await widget.picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      _generateText(imageFile);
    }
  }

  Future<void> _getFileAndGenerateText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      File imageFile = File(result.files.single.path!);
      _generateText(imageFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Green Guard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => _getImageAndGenerateText(ImageSource.camera),
                child: const Icon(Icons.camera),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getFileAndGenerateText,
                child: const Icon(Icons.image),
              ),
              const SizedBox(height: 20),
              const Text(
                'Generated Text:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _generatedText,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
