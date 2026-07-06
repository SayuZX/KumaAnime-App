import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'encryption_service.dart';

class AesGcmService implements EncryptionService {
  static const int _keySize = 32;
  static const int _ivSize = 12;

  @override
  int get keySize => _keySize;

  @override
  int get ivSize => _ivSize;

  @override
  Uint8List generateIV() {
    final random = Random.secure();
    final iv = Uint8List(_ivSize);
    for (var i = 0; i < _ivSize; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  @override
  Future<Uint8List> encrypt(Uint8List data, Uint8List key, Uint8List iv) async {
    if (key.length != _keySize) {
      throw ArgumentError('Key must be $_keySize bytes');
    }
    if (iv.length != _ivSize) {
      throw ArgumentError('IV must be $_ivSize bytes');
    }

    final encrypter = encrypt_lib.Encrypter(
      encrypt_lib.AES(
        encrypt_lib.Key(key),
        mode: encrypt_lib.AESMode.gcm,
      ),
    );

    final encrypted = encrypter.encryptBytes(
      data,
      iv: encrypt_lib.IV(iv),
    );

    return Uint8List.fromList(encrypted.bytes);
  }

  @override
  Future<Uint8List> decrypt(Uint8List encryptedData, Uint8List key, Uint8List iv) async {
    if (key.length != _keySize) {
      throw ArgumentError('Key must be $_keySize bytes');
    }
    if (iv.length != _ivSize) {
      throw ArgumentError('IV must be $_ivSize bytes');
    }

    final encrypter = encrypt_lib.Encrypter(
      encrypt_lib.AES(
        encrypt_lib.Key(key),
        mode: encrypt_lib.AESMode.gcm,
      ),
    );

    final decrypted = encrypter.decryptBytes(
      encrypt_lib.Encrypted(encryptedData),
      iv: encrypt_lib.IV(iv),
    );

    return Uint8List.fromList(decrypted);
  }
}
