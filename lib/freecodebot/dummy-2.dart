// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Free Code Bot",
      theme: ThemeData(primarySwatch: Colors.amber),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _image;
  bool _isSending = false;
  String customPrompt = '';
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];

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
    String apiKey = "AIzaSyA2KXpQhBjtK_91mk2Wd-TNBkIMtKaEVsA";
    String geminiProVision =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro-vision-latest:generateContent?key=$apiKey";
    String geminiVision =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent?key=$apiKey";
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {
              "text": customPrompt == ''
                  ? "identify the image and provide the details of the image"
                  : customPrompt
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
      Uri.parse(customPrompt == "" ? geminiVision : geminiProVision),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    print("Sent : $customPrompt");
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody = json.decode(response.body);
      setState(() {
        String responseBody =
            jsonBody["candidates"][0]["content"]["parts"][0]["text"];
        _messages.insert(
          0,
          ChatMessage(
            text: responseBody,
            isUserMessage: false,
          ),
        );
        _isSending = false;
        _image = null; // Clear selected image
        _controller.clear(); // Clear text prompt
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

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    String apiKey = "AIzaSyA2KXpQhBjtK_91mk2Wd-TNBkIMtKaEVsA";

    String geminiProVision =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro-vision-latest:generateContent?key=$apiKey";

    String geminiVision =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent?key=$apiKey";
    String requestBody = json.encode({
      "contents": [
        {
          "parts": [
            {"text": text},
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
      Uri.parse(_image == null ? geminiVision : geminiProVision),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    print("Sent : $text");
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody = json.decode(response.body);
      setState(() {
        String responseBody =
            jsonBody["candidates"][0]["content"]["parts"][0]["text"];
        _messages.insert(
          0,
          ChatMessage(
            text: responseBody,
            isUserMessage: false,
          ),
        );
        _isSending = false;
        _controller.clear(); // Clear text prompt
      });
      print("Text processed");
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
        title: const Text("Free Code Bot"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              children: <Widget>[
                for (var message in _messages) _buildMessage(message),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: 300,
                  child: _image == null
                      ? const Center(
                          child: Text("Provide your query and question image"))
                      : Image.file(File(_image!.path)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 40, right: 20),
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          width: 5,
                        ),
                      ),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.attach_file_rounded),
                        onPressed: _pickFile,
                      ),
                      suffixIcon: _isSending
                          ? const CircularProgressIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    sendMessage(_controller.text);
                                  },
                                  icon: const Icon(Icons.send),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _image == null
                                        ? Icons.camera_alt
                                        : Icons.send,
                                  ),
                                  onPressed: () {
                                    if (_image == null) {
                                      _openCamera();
                                    } else {
                                      sendImage(_image);
                                    }
                                  },
                                ),
                              ],
                            ),
                    ),
                    onChanged: (value) => customPrompt = value,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.isUserMessage;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
  });
}
