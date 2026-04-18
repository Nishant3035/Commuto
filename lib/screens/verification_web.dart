import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

/// Web implementation — simulates scanning since ML Kit is not available on web.
Future<Map<String, String?>?> scanImage(XFile image) async {
  // Simulate processing time
  await Future.delayed(const Duration(seconds: 2));

  // Return demo data on web
  return {
    'name': AuthService.fullName.isNotEmpty ? AuthService.fullName : 'Demo Student',
    'college': 'Verified College',
    'id': 'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
  };
}
