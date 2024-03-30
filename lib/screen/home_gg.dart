import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _image;
  String _responseBody = '';
  bool _isSending = false;

  _openCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      _cropImage(image.path);
    }
  }

  _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      String imagePath = result.files.single.path!;
      _cropImage(imagePath);
    }
  }

  _cropImage(String imagePath) async {
    ImageCropper cropper = ImageCropper();
    final croppedImage = await cropper.cropImage(
      sourcePath: imagePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      iosUiSettings: const IOSUiSettings(
        title: 'Cropper',
      ),
    );
    if (croppedImage != null) {
      setState(() {
        _image = XFile(croppedImage.path);
      });
    }
  }

  Future<void> sendImage(XFile? imageFile) async {
    if (imageFile == null) return;

    setState(() {
      _isSending = true;
    });

    String base64Image = base64Encode(File(imageFile.path).readAsBytesSync());
    String apiKey =
        "AIzaSyA2KXpQhBjtK_91mk2Wd-TNBkIMtKaEVsA"; // Replace with your actual API key
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Please analyze the provided image to identify any diseases in plants, trees, vegetables, or fruits. If a disease is detected, suggest remedies and mention possible causes. If the image doesn't contain relevant subjects, state it's not suitable for analysis, and if it's unclear, mention it's not clear for analysis."
            },
            {
              "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
            },
            {"text": "\n\n"}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.8,
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
    http.Response response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro-vision-latest:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody = json.decode(response.body);
      setState(() {
        _responseBody =
            jsonBody["candidates"][0]["content"]["parts"][0]["text"];
        _isSending = false;
      });
      print("Image processed");
    } else {
      print("Request failed");
      setState(() {
        _isSending = false;
      });
    }
    print(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Green Guard"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _image == null
                    ? const Text("No image is selected")
                    : Image.file(File(_image!.path)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Text(_responseBody),
                )
              ],
            ),
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
                onPressed: _pickFile,
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
