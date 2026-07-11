import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  // Thay thế bằng thông tin Cloudinary của bạn
  static const String cloudName = 'uq2q3uim'; // Cloud Name của bạn
  static const String uploadPreset =
      'flutter_upload'; // Thay thế bằng Upload Preset của bạn

  // Upload 1 ảnh lên Cloudinary (unsigned - không cần secret)
  static Future<String> uploadImage(File imageFile) async {
    try {
      print('=== Bắt đầu upload ảnh lên Cloudinary ===');
      print('File path: ${imageFile.path}');

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri);

      // Thêm upload preset
      request.fields['upload_preset'] = uploadPreset;
      print('Upload preset: $uploadPreset');

      // Thêm file ảnh vào request
      final file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);
      print('Đã thêm file vào request: ${file.filename}');

      // Gửi request
      print('Đang gửi request đến Cloudinary...');
      final response = await request.send();
      print('Status code: ${response.statusCode}');

      // Đọc phản hồi
      final responseString = await response.stream.bytesToString();
      print('Phản hồi từ Cloudinary: $responseString');

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseString);
        final secureUrl = jsonData['secure_url'];
        print('Upload thành công! Link ảnh: $secureUrl');
        return secureUrl;
      } else {
        throw Exception(
          'Lỗi kết nối Cloudinary: ${response.statusCode}, Phản hồi: $responseString',
        );
      }
    } catch (e) {
      print('Lỗi trong uploadImage: $e');
      throw Exception('Lỗi upload ảnh lên Cloudinary: $e');
    }
  }

  // Upload nhiều ảnh lên Cloudinary
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> imageUrls = [];

    for (final file in imageFiles) {
      final url = await uploadImage(file);
      imageUrls.add(url);
    }

    return imageUrls;
  }
}
