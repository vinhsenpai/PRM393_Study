import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dvoexcswb';
  static const String uploadPreset = 'PRM_flutter_app';

  // Upload 1 ảnh lên Cloudinary (unsigned)
  static Future<String> uploadImage(XFile imageFile) async {
    try {
      print('=== Bắt đầu upload ảnh lên Cloudinary ===');
      print('File name: ${imageFile.name}');

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri);

      // Thêm upload preset
      request.fields['upload_preset'] = uploadPreset;
      print('Upload preset: $uploadPreset');

      // Đọc file thành bytes (chạy tốt trên cả Web và Mobile)
      final bytes = await imageFile.readAsBytes();
      final file = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      );
      request.files.add(file);
      print('Đã thêm file vào request: ${imageFile.name}');

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
  static Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    final List<String> imageUrls = [];

    for (final file in imageFiles) {
      final url = await uploadImage(file);
      imageUrls.add(url);
    }

    return imageUrls;
  }
}

