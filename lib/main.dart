import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PyToPycPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PyToPycPage extends StatefulWidget {
  const PyToPycPage({super.key});

  @override
  State<PyToPycPage> createState() => _PyToPycPageState();
}

class _PyToPycPageState extends State<PyToPycPage> {
  File? selectedFile;
  String status = 'لم يتم اختيار ملف بعد';
  String? downloadPath;

  final String apiUrl = 'https://beb97cf8-5095-450d-880c-57dd6cec2acd-00-17qhujgbbpxfh.pike.replit.dev/upload';
  
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['py'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        status = 'تم اختيار الملف: ${result.files.single.name}';
        downloadPath = null;
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) {
      setState(() {
        status = 'الرجاء اختيار ملف أولاً';
      });
      return;
    }

    setState(() {
      status = 'جارٍ رفع الملف...';
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', selectedFile!.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var bytes = await response.stream.toBytes();
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/result.pyc';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        setState(() {
          status = 'تم التحويل بنجاح، الملف محفوظ هنا: $filePath';
          downloadPath = filePath;
        });
      } else {
        setState(() {
          status = 'فشل التحويل، رمز الخطأ: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        status = 'حدث خطأ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل .py إلى .pyc'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text('اختر ملف .py'),
            ),
            const SizedBox(height: 20),
            Text(status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadFile,
              child: const Text('رفع وتحويل الملف'),
            ),
            if (downloadPath != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // يمكن إضافة فتح الملف أو مشاركته هنا
                },
                child: const Text('فتح الملف الناتج'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
