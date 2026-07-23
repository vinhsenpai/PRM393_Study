import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorUtils {
  /// Converts FirebaseAuth exceptions or generic errors into human-readable messages.
  static String parseAuthErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Email này đã được sử dụng cho một tài khoản khác.';
        case 'invalid-email':
          return 'Địa chỉ email không hợp lệ.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng nhập mật khẩu từ 6 ký tự trở lên.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không chính xác.';
        case 'user-disabled':
          return 'Tài khoản này đã bị khóa.';
        case 'too-many-requests':
          return 'Tài khoản bị tạm khóa do nhập sai nhiều lần. Vui lòng thử lại sau.';
        case 'operation-not-allowed':
          return 'Phương thức đăng nhập này chưa được kích hoạt.';
        default:
          final msg = error.message;
          if (msg != null && msg.isNotEmpty) {
            return msg;
          }
          return 'Đã xảy ra lỗi xác thực (${error.code}).';
      }
    }
    
    final rawMsg = error.toString();
    if (rawMsg.startsWith('Exception: ')) {
      return rawMsg.substring(11);
    }
    return rawMsg;
  }
}
