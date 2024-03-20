// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart ' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _image;
  String _responseBody = '';
  bool _isSending = false;

  _openCamera() {
    if (_image == null) {
      _getImageFromCamera();
    }
  }

  Future<void> _getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      ImageCropper cropper = ImageCropper();
      final croppedImage = await cropper.cropImage(
          sourcePath: image.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
          iosUiSettings: const IOSUiSettings(
            title: 'Cropper',
          ));
      setState(() {
        _image = croppedImage != null ? XFile(croppedImage.path) : null;
      });
    }
  }

  Future<void> _getImageFromFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _image = XFile(file.path);
      });
    }
  }

  Future<void> sendImage(XFile? imagefile) async {
    if (imagefile == null) return;

    setState(() {
      _isSending = true;
    });

    String base64Image = base64Encode(File(imagefile.path).readAsBytesSync());
    String apikey =
        "AIzaSyDpYPMArz430gNLYaGQZJsR1P7zC6biI0o"; // Replace with your actual API key

    // Construct the request body
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "describe the tree/plants and it's disease then provde the ways to prevent and cure for it\n"
            },
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 4096,
        "stopSequences": []
      },
      "safetySettings": [
        {
          "category": "HARM_CATEGORY_HARASSMENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_HATE_SPEECH",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
    });

    try {
      // Make the HTTP POST request with the API key in the headers
      http.Response response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro-vision-latest:generateContent?key=$apikey"),
        headers: {
          'Content-Type': "application/json",
          'Authorization':
              'Bearer $apikey', // Replace $apikey with your actual key
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonBody = json.decode(response.body);
        setState(() {
          _responseBody =
              jsonBody["candidates"][0]['content']['parts'][0]['text'];
          _isSending = false;
        });
        print("Image sent successfully");
      } else {
        print("Request failed");
        setState(() {
          _isSending = false;
        });
      }
    } catch (e) {
      print("Error sending image: $e");
      // Handle exception
    }
    //print(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Green guard"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(children: [
              _image == null
                  ? const Text("No image is selected")
                  : Image.file(File(_image!.path)),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(_responseBody),
              )
            ]),
          ),
          if (_isSending)
            const Center(
              child: CircularProgressIndicator(),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _image == null ? _openCamera() : sendImage(_image);
        },
        tooltip: _image == null ? "pick images" : "Send image",
        child: Icon(_image == null ? Icons.camera_alt : Icons.send),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: _getImageFromFile,
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _openCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
