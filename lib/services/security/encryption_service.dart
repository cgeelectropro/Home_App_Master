import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/app_logger.dart';

class EncryptionService {
  static const String _keyKey = 'encryption_key';
  static const String _ivKey = 'encryption_iv';
  final FlutterSecureStorage _storage;
  late Encrypter _encrypter;
  late IV _iv;

  EncryptionService({FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> initialize() async {
    try {
      // Get or generate encryption key
      String? storedKey = await _storage.read(key: _keyKey);
      String? storedIV = await _storage.read(key: _ivKey);

      if (storedKey == null || storedIV == null) {
        await _generateNewKeys();
      } else {
        _setupEncryption(
          base64.decode(storedKey),
          base64.decode(storedIV),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to initialize encryption', e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> _generateNewKeys() async {
    try {
      // Generate random key and IV
      final key = Key.fromSecureRandom(32);
      final iv = IV.fromSecureRandom(16);

      // Store them securely
      await _storage.write(key: _keyKey, value: base64.encode(key.bytes));
      await _storage.write(key: _ivKey, value: base64.encode(iv.bytes));

      _setupEncryption(key.bytes, iv.bytes);
    } catch (e) {
      AppLogger.logError('Failed to generate keys', e, StackTrace.current);
      rethrow;
    }
  }

  void _setupEncryption(List<int> keyBytes, List<int> ivBytes) {
    final key = Key(Uint8List.fromList(keyBytes));
    _iv = IV(Uint8List.fromList(ivBytes));
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  }

  String encrypt(String data) {
    try {
      final encrypted = _encrypter.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      AppLogger.logError('Encryption failed', e, StackTrace.current);
      rethrow;
    }
  }

  String decrypt(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      AppLogger.logError('Decryption failed', e, StackTrace.current);
      rethrow;
    }
  }

  String generateHMAC(String data) {
    try {
      final key = Key.fromSecureRandom(32);
      final hmac = Hmac(sha256, key.bytes);
      final digest = hmac.convert(utf8.encode(data));
      return base64.encode(digest.bytes);
    } catch (e) {
      AppLogger.logError('HMAC generation failed', e, StackTrace.current);
      rethrow;
    }
  }

  bool verifyHMAC(String data, String signature) {
    try {
      final expectedSignature = generateHMAC(data);
      return signature == expectedSignature;
    } catch (e) {
      AppLogger.logError('HMAC verification failed', e, StackTrace.current);
      return false;
    }
  }
}
