import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File to PDF Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'File to PDF Converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PlatformFile? selectedFile;
  String? selectedFormat = 'jpg'; // Default selected format
  String statusMessage = '';

  // Replace with your actual ConvertAPI secret
  final String convertApiSecret = 'secret_IlSh106XkHP3c5a1';

  // Map of format to API endpoints for each conversion
  final Map<String, String> conversionEndpoints = {
    'jpg': 'https://v2.convertapi.com/convert/jpg/to/pdf',
    'jpeg': 'https://v2.convertapi.com/convert/jpeg/to/pdf',
    'png': 'https://v2.convertapi.com/convert/png/to/pdf',
    'doc': 'https://v2.convertapi.com/convert/doc/to/pdf',
    'docx': 'https://v2.convertapi.com/convert/docx/to/pdf',
    'ppt': 'https://v2.convertapi.com/convert/ppt/to/pdf',
    'xls': 'https://v2.convertapi.com/convert/xls/to/pdf',
    'html': 'https://v2.convertapi.com/convert/html/to/pdf',
    'csv': 'https://v2.convertapi.com/convert/csv/to/pdf',
  };

  Future<void> _pickFile() async {
    // Pick files based on the selected format
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: [selectedFormat!],
      type: FileType.custom,
    );
    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
        statusMessage = '';
      });
    } else {
      setState(() {
        statusMessage = 'File selection canceled.';
      });
    }
  }

  Future<void> _convertToPdf() async {
    if (selectedFile == null) {
      setState(() {
        statusMessage = 'Please select a file first';
      });
      return;
    }

    setState(() {
      statusMessage = 'Converting...';
    });

    // Base64 encode the selected file
    final base64FileData = base64Encode(selectedFile!.bytes!);

    // Prepare the request body for ConvertAPI
    final requestBody = jsonEncode({
      "Parameters": [
        {
          "Name": "File",
          "FileValue": {
            "Name": selectedFile!.name,
            "Data": base64FileData,
          }
        },
        {
          "Name": "StoreFile",
          "Value": true,
        }
      ]
    });

    // Select the API endpoint based on the selected format
    final url = Uri.parse(conversionEndpoints[selectedFormat]!);

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $convertApiSecret',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        // Parse response to get the download URL for the converted PDF
        final responseBody = jsonDecode(response.body);
        final convertedFiles = responseBody['Files'];
        if (convertedFiles is List && convertedFiles.isNotEmpty) {
          final downloadUrl = convertedFiles[0]['Url'];

          // Trigger a file download in the web browser
          html.AnchorElement anchor = html.AnchorElement(href: downloadUrl)
            ..setAttribute("download", "converted_file.pdf")
            ..click();

          setState(() {
            statusMessage =
                'File converted successfully. Download should start automatically.';
          });
        } else {
          setState(() {
            statusMessage = 'Conversion successful, but no files returned.';
          });
        }
      } else {
        setState(() {
          statusMessage = 'Conversion failed: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<String>(
              value: selectedFormat,
              onChanged: (String? newFormat) {
                setState(() {
                  selectedFormat = newFormat;
                  selectedFile = null; // Reset file selection on format change
                  statusMessage = '';
                });
              },
              items: conversionEndpoints.keys
                  .map<DropdownMenuItem<String>>((String format) {
                return DropdownMenuItem<String>(
                  value: format,
                  child: Text(format.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select File'),
            ),
            const SizedBox(height: 20),
            if (selectedFile != null)
              Text('Selected file: ${selectedFile!.name}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _convertToPdf,
              child: const Text('Convert to PDF'),
            ),
            const SizedBox(height: 20),
            Text(statusMessage),
          ],
        ),
      ),
    );
  }
}
