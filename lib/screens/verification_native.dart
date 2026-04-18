import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Native (mobile) implementation — uses Google ML Kit for real OCR scanning.
Future<Map<String, String?>?> scanImage(XFile image) async {
  final inputImage = InputImage.fromFile(File(image.path));
  final textRecognizer = TextRecognizer();
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  textRecognizer.close();

  final fullText = recognizedText.text;

  if (fullText.trim().isEmpty) {
    return null;
  }

  return _extractInfo(fullText);
}

Map<String, String?> _extractInfo(String text) {
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  String? name;
  String? college;
  String? studentId;

  final collegeKeywords = [
    'college', 'university', 'institute', 'polytechnic', 'school',
    'academy', 'vidyalaya', 'engineering', 'technology', 'thakur',
    'somaiya', 'spit', 'dj sanghvi', 'mumbai', 'education',
  ];

  final idKeywords = ['id', 'roll', 'enrollment', 'reg', 'prn', 'student no', 'no.'];

  for (final line in lines) {
    final lower = line.toLowerCase();

    if (college == null && collegeKeywords.any((k) => lower.contains(k))) {
      college = line;
      continue;
    }

    if (studentId == null && (idKeywords.any((k) => lower.contains(k)) || RegExp(r'^[A-Z0-9]{6,}$').hasMatch(line))) {
      studentId = line;
      continue;
    }

    if (name == null && RegExp(r'^[A-Za-z\s\.]{4,40}$').hasMatch(line)) {
      final words = line.split(' ');
      if (words.length >= 2 && words.length <= 5) {
        final isName = words.every((w) => w.isNotEmpty && w[0] == w[0].toUpperCase());
        if (isName && !collegeKeywords.any((k) => lower.contains(k))) {
          name = line;
        }
      }
    }
  }

  return {'name': name, 'college': college, 'id': studentId};
}
