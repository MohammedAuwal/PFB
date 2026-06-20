import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pfb/core/constants/cloudinary_config.dart';

class CloudinaryService {
  Future<String> uploadImage(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    );

    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = (data['secure_url'] ?? '').toString();

      if (secureUrl.isEmpty) {
        throw Exception('Cloudinary upload succeeded but returned empty URL');
      }

      return secureUrl;
    }

    throw Exception('Cloudinary upload failed: ${response.body}');
  }
}
