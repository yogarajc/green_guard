import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:translator/translator.dart' as translator;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Guard',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const DesignHome(),
    );
  }
}

class DesignHome extends StatefulWidget {
  const DesignHome({Key? key}) : super(key: key);

  @override
  _DesignHomeState createState() => _DesignHomeState();
}

class _DesignHomeState extends State<DesignHome> {
  XFile? _image;
  String _responseBody = '';
  bool _isSending = false;
  bool _isTamil = false;

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
      // Send the cropped image for analysis
      sendImage(_image);
    }
  }

  Future<void> translateText(String text) async {
    if (!_isTamil) {
      // If English is selected, no need to translate
      setState(() {
        _responseBody = text;
      });
      return;
    }

    // Translate the text to Tamil
    final translatedText = await translator.GoogleTranslator().translate(
      text,
      from: 'en',
      to: 'ta',
    );

    setState(() {
      _responseBody = translatedText.toString();
    });
  }

  Future<void> sendImage(XFile? imageFile) async {
    if (imageFile == null) return;

    setState(() {
      _isSending = true;
    });

    String base64Image = base64Encode(File(imageFile.path).readAsBytesSync());
    String apiKey = "AIzaSyA2KXpQhBjtK_91mk2Wd-TNBkIMtKaEVsA";
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Investigate the provided image to identify diseases in plants, trees, vegetables, or fruits. If any diseases are found, provide remedies and discuss potential causes. Also, mention if the image lacks relevant subjects or if its quality is poor. The output format should include three sections with subtitles: Definition, Analysis, and Cure. In the Definition section, examine the image for diseases and discuss remedies and causes if applicable. The Analysis section should describe the image's content, identify specific diseases or issues observed, and explain symptoms. Enumerate potential causes of the observed disease in the Cause section, including factors like fungal infection, pest infestation, nutrient deficiency, and environmental stress, while also mentioning relevant environmental or cultural factors. Finally, recommend remedies in the Cure section, such as applying fungicides, pruning affected areas, improving soil drainage, and enhancing nutrient levels, along with additional steps to control disease spread and enhance overall plant/tree/vegetable/fruit health."
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
      final responseBody =
          jsonBody["candidates"][0]["content"]["parts"][0]["text"];

      // Translate the response text
      await translateText(responseBody);
    } else {
      print("Request failed");
    }

    setState(() {
      _isSending = false;
    });

    print(response.body);
  }

  void _toggleLanguage() async {
    setState(() {
      _isTamil = !_isTamil;
    });

    // Translate the response text to the selected language
    await translateText(_responseBody);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Image.asset("assets/logo1.png"), // Replace with your logo
        ),
        title: const Text("Green Guard"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (_image != null) Image.file(File(_image!.path)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: _responseBody.isEmpty
                      ? RichText(
                          text: const TextSpan(
                            text: "Got a sick plant?",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.red, // Change color to red
                            ),
                            children: [
                              TextSpan(
                                text:
                                    "\n    Green Guard here to help! Upload a picture of your plant",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          _responseBody,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Arial', // Change font to Tamil font
                          ),
                        ),
                )
              ],
            ),
          ),
          if (_isSending)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          _openCamera();
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.green[400],
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
                icon: const Icon(Icons.language),
                onPressed: _toggleLanguage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
