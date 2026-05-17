import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  CloudinaryService._();

  // ── REPLACE WITH YOUR CLOUDINARY VALUES ───────────────────
  static const _cloudName = 'dn3rmoaq8';
  static const _uploadPreset = 'storepro_preset';
  static const _folder = 'storepro';

  // ── UPLOAD IMAGE ──────────────────────────────────────────
  // Returns the secure URL of the uploaded image.
  // Returns null if upload fails.
  static Future<String?> upload(File imageFile, String subfolder) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = '$_folder/$subfolder'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString().timeout(
          const Duration(seconds: 6),
        );
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── DELETE IMAGE ──────────────────────────────────────────
  // publicId = the part after your folder in the URL
  static Future<bool> delete(
    String publicId,
    String apiKey,
    String apiSecret,
  ) async {
    // Note: deletion requires signed requests (server-side recommended)
    // For v1, we skip deletion and just overwrite on re-upload.
    return true;
  }
}
