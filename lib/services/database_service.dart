// lib/services/database_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as path;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class DatabaseService {
  Future<String?> pickDatabaseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['isar'],
    );

    return result?.files.single.path;
  }

  Future<bool> isEncrypted(String filePath) async {
    try {
      // Try to open without a password - if it works, it's not encrypted
      final dir = path.dirname(filePath);
      final name = path.basenameWithoutExtension(filePath);

      final isar = await Isar.open(
        [],
        directory: dir,
        name: name,
        inspector: false,
      );

      await isar.close();
      return false;
    } catch (e) {
      if (e.toString().contains('encryption key') ||
          e.toString().contains('encrypted') ||
          e.toString().contains('decrypt')) {
        return true;
      }
      rethrow;
    }
  }

  Future<void> encryptDatabase(String filePath, String password) async {
    final dir = path.dirname(filePath);
    final name = path.basenameWithoutExtension(filePath);

    try {
      // First check if it's already encrypted
      if (await isEncrypted(filePath)) {
        throw Exception('Database is already encrypted');
      }

      // Close any existing instances that might be using the file
      Isar? existingInstance = Isar.getInstance('$dir/$name');
      if (existingInstance != null) {
        await existingInstance.close();
      }

      // Read the unencrypted file
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        throw Exception('Database file not found');
      }

      final fileBytes = await originalFile.readAsBytes();

      // Create a backup before encrypting
      final backupPath = '$filePath.bak';
      await originalFile.copy(backupPath);

      // Encrypt file content using our encryption method
      final encryptedBytes = _encryptFileContent(fileBytes, password);

      // Write encrypted content back to original file
      await originalFile.writeAsBytes(encryptedBytes);

      return;
    } catch (e) {
      if (e is Exception && e.toString().contains('already encrypted')) {
        rethrow;
      }

      // Try to restore from backup if encryption failed
      final backupPath = '$filePath.bak';
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.copy(filePath);
        await backupFile.delete();
      }

      throw Exception('Failed to encrypt database: ${e.toString()}');
    }
  }

  Future<void> decryptDatabase(String filePath, String password) async {
    final dir = path.dirname(filePath);
    final name = path.basenameWithoutExtension(filePath);

    try {
      // First check if it's encrypted
      if (!await isEncrypted(filePath)) {
        throw Exception('Database is not encrypted');
      }

      // Close any existing instances that might be using the file
      Isar? existingInstance = Isar.getInstance('$dir/$name');
      if (existingInstance != null) {
        await existingInstance.close();
      }

      // Read the encrypted file
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        throw Exception('Database file not found');
      }

      final encryptedBytes = await originalFile.readAsBytes();

      // Create a backup before decrypting
      final backupPath = '$filePath.enc.bak';
      await originalFile.copy(backupPath);

      // Decrypt file content
      final decryptedBytes = _decryptFileContent(encryptedBytes, password);

      // Write decrypted content back to original file
      await originalFile.writeAsBytes(decryptedBytes);

      // Verify that the file is now decrypted by trying to open it
      try {
        final isar = await Isar.open(
          [],
          directory: dir,
          name: name,
          inspector: false,
        );
        await isar.close();
      } catch (e) {
        // If we can't open it, decryption failed
        // Restore from backup
        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.copy(filePath);
        }
        throw Exception(
          'Failed to decrypt database: Invalid password or corrupted file',
        );
      }

      return;
    } catch (e) {
      if (e is Exception && e.toString().contains('not encrypted')) {
        rethrow;
      }
      throw Exception('Failed to decrypt database: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getDatabaseInfo(String filePath) async {
    final file = File(filePath);
    final fileSize = await file.length();
    final lastModified = await file.lastModified();

    // Check if encrypted
    final isEncrypted = await this.isEncrypted(filePath);

    return {
      'path': filePath,
      'size': fileSize,
      'lastModified': lastModified.toString(),
      'fileName': path.basename(filePath),
      'isEncrypted': isEncrypted,
    };
  }

  Future<List<String>> getDatabaseKeys(String filePath) async {
    try {
      final dir = path.dirname(filePath);
      final name = path.basenameWithoutExtension(filePath);

      // Try to open without encryption
      try {
        final isar = await Isar.open(
          [],
          directory: dir,
          name: name,
          inspector: false,
        );

        await isar.close();

        // If we can't get collection names directly, return some basic info
        return ['Database opened successfully'];
      } catch (e) {
        if (e.toString().contains('encryption key') ||
            e.toString().contains('encrypted') ||
            e.toString().contains('decrypt')) {
          return ['Database is encrypted - decrypt first to view collections'];
        }
        return ['Error reading database: ${e.toString()}'];
      }
    } catch (e) {
      return ['Error accessing database: ${e.toString()}'];
    }
  }

  // Convert a password to a 256-bit AES key using PBKDF2
  encrypt.Key _deriveKey(String password) {
    // Generate a salt (ideally this would be stored and reused)
    final salt = List<int>.filled(16, 42); // Fixed salt for compatibility

    // Use PBKDF2 with multiple iterations for key strengthening
    final pbkdf2Bytes = _pbkdf2(
      password: utf8.encode(password),
      salt: salt,
      iterations: 1000, // Higher iterations = more secure but slower
      keyLength: 32, // 256 bits for AES-256
    );

    return encrypt.Key(Uint8List.fromList(pbkdf2Bytes));
  }

  // PBKDF2 implementation using HMAC-SHA256
  List<int> _pbkdf2({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final hmac = Hmac(sha256, password);
    final numBlocks = (keyLength / 32).ceil();
    final result = <int>[];

    for (var i = 1; i <= numBlocks; i++) {
      final block = _pbkdf2Block(hmac, salt, iterations, i);
      result.addAll(block);
    }

    return result.sublist(0, keyLength);
  }

  List<int> _pbkdf2Block(
    Hmac hmac,
    List<int> salt,
    int iterations,
    int blockNumber,
  ) {
    final blockNumberBytes = [
      (blockNumber >> 24) & 0xFF,
      (blockNumber >> 16) & 0xFF,
      (blockNumber >> 8) & 0xFF,
      blockNumber & 0xFF,
    ];

    var u = hmac.convert([...salt, ...blockNumberBytes]).bytes;
    var result = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  // Encrypt file content
  Uint8List _encryptFileContent(Uint8List fileBytes, String password) {
    // Generate a key from the password
    final key = _deriveKey(password);

    // Create an encrypter with AES in CBC mode
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    // Generate a random IV for this encryption
    final iv = encrypt.IV.fromSecureRandom(16);

    // Encrypt the data
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // Combine IV and encrypted data
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  // Decrypt file content
  Uint8List _decryptFileContent(Uint8List encryptedBytes, String password) {
    if (encryptedBytes.length < 17) {
      throw Exception('File too small to be encrypted');
    }

    // Extract IV from the first 16 bytes
    final iv = encrypt.IV(Uint8List.fromList(encryptedBytes.sublist(0, 16)));

    // Extract encrypted data
    final encryptedData = encryptedBytes.sublist(16);

    // Generate a key from the password
    final key = _deriveKey(password);

    // Create an encrypter with AES in CBC mode
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    // Decrypt the data
    try {
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(encryptedData)),
        iv: iv,
      );
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: Invalid password or corrupted file');
    }
  }
}
