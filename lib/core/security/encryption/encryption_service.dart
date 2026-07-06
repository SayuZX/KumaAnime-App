import 'dart:typed_data';

abstract class EncryptionService {
  Future<Uint8List> encrypt(Uint8List data, Uint8List key, Uint8List iv);
  Future<Uint8List> decrypt(Uint8List encryptedData, Uint8List key, Uint8List iv);
  Uint8List generateIV();
  int get keySize;
  int get ivSize;
}
