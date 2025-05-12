import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  // 32-character key for AES-256 encryption
  static final _key = Key.fromUtf8('Cq1x8U7v9z5Y3LbVtN2mKdXeRgBpHsJQ'); // Make sure it's exactly 32 chars
  static final _iv = IV.fromLength(16); // AES requires a 16-byte IV

  /// Encrypts a plain text string and returns the Base64-encoded ciphertext
  static String encrypt(String plainText) {
    final encrypter = Encrypter(AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a Base64-encoded encrypted string and returns the original plain text
  static String decrypt(String encryptedText) {
    final encrypter = Encrypter(AES(_key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}