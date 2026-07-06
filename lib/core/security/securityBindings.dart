import 'dart:ffi';
import 'dart:io';

typedef _CopyrightNative = Pointer<Uint8> Function();
typedef _CopyrightDart = Pointer<Uint8> Function();

typedef _U32Native = Uint32 Function();
typedef _U32Dart = int Function();

typedef _IntNative = Int32 Function();
typedef _IntDart = int Function();

typedef _TokenNative = Uint64 Function(Uint64, Uint64);
typedef _TokenDart = int Function(int, int);

typedef _ValidateNative = Int32 Function(Uint64, Uint64, Uint64);
typedef _ValidateDart = int Function(int, int, int);

typedef _XorBufferNative = Void Function(Pointer<Uint8>, Uint32, Pointer<Uint8>, Uint32);
typedef _XorBufferDart = void Function(Pointer<Uint8>, int, Pointer<Uint8>, int);

typedef _DeriveSeedNative = Uint64 Function(Uint64, Uint64);
typedef _DeriveSeedDart = int Function(int, int);

typedef _SecureZeroNative = Void Function(Pointer<Uint8>, Uint32);
typedef _SecureZeroDart = void Function(Pointer<Uint8>, int);

class SecurityBindings {
  static DynamicLibrary? _lib;

  static bool get isLoaded => _lib != null;

  static bool load() {
    if (_lib != null) return true;
    try {
      _lib = Platform.isAndroid ? DynamicLibrary.open('libkuma_security.so') : DynamicLibrary.process();
      return true;
    } catch (_) {
      _lib = null;
      return false;
    }
  }

  static int copyrightHash() => _lib!.lookupFunction<_U32Native, _U32Dart>('kuma_copyright_hash')();

  static int selfChecksum() => _lib!.lookupFunction<_U32Native, _U32Dart>('kuma_self_checksum')();

  static int antiDebug() => _lib!.lookupFunction<_IntNative, _IntDart>('kuma_anti_debug')();

  static int sessionToken(int hwSeed, int timestamp) =>
      _lib!.lookupFunction<_TokenNative, _TokenDart>('kuma_session_token')(hwSeed, timestamp);

  static int validateToken(int token, int hwSeed, int timestamp) =>
      _lib!.lookupFunction<_ValidateNative, _ValidateDart>('kuma_validate_token')(token, hwSeed, timestamp);

  static String copyright() {
    final ptr = _lib!.lookupFunction<_CopyrightNative, _CopyrightDart>('kuma_copyright')();
    final bytes = <int>[];
    for (var i = 0; i < 256; i++) {
      final b = (ptr + i).value;
      if (b == 0) break;
      bytes.add(b);
    }
    return String.fromCharCodes(bytes);
  }

  static void xorBuffer(Pointer<Uint8> buffer, int length, Pointer<Uint8> key, int keyLen) =>
      _lib!.lookupFunction<_XorBufferNative, _XorBufferDart>('kuma_xor_buffer')(buffer, length, key, keyLen);

  static int deriveSeed(int base, int salt) =>
      _lib!.lookupFunction<_DeriveSeedNative, _DeriveSeedDart>('kuma_derive_seed')(base, salt);

  static int checkRoot() => _lib!.lookupFunction<_IntNative, _IntDart>('kuma_check_root')();

  static void secureZero(Pointer<Uint8> ptr, int len) =>
      _lib!.lookupFunction<_SecureZeroNative, _SecureZeroDart>('kuma_secure_zero')(ptr, len);
}
