// Unit tests for FileStorageService.
//
// Covers all four public methods:
//   saveImage, getAbsolutePath, deletePageFile, deleteNotationDirectory.
//
// Uses a real temporary directory (via [Directory.systemTemp]) so that actual
// file-system semantics are exercised without relying on a real Android
// appDocDir. The [FileStorageService] accepts a [dirProvider] callback that is
// overridden to return the temp directory in every test group.
//
// Each test group creates a fresh temp dir in setUp and deletes it in tearDown
// to guarantee full isolation.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:swaralipi/core/storage/file_storage_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a temp directory and returns a [FileStorageService] that uses it.
FileStorageService _makeService(Directory tempDir) {
  return FileStorageService(dirProvider: () async => tempDir);
}

/// Minimal valid JPEG header (two bytes) — enough to round-trip the test.
final Uint8List _minimalJpeg = Uint8List.fromList([0xFF, 0xD8]);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('FileStorageService.saveImage', () {
    late Directory tempDir;
    late FileStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fss_test_save_');
      service = _makeService(tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('writes bytes to expected absolute path', () async {
      final relativePath = await service.saveImage(_minimalJpeg, 'n1', 0);

      final absPath = await service.getAbsolutePath(relativePath);
      final file = File(absPath);

      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), equals(_minimalJpeg));
    });

    test('returns path matching notations/<notationId>/page_<idx>_original.jpg',
        () async {
      final relativePath = await service.saveImage(_minimalJpeg, 'abc-123', 2);

      expect(
        relativePath,
        equals(p.join('notations', 'abc-123', 'page_2_original.jpg')),
      );
    });

    test('creates parent directories when they do not exist', () async {
      final relativePath =
          await service.saveImage(_minimalJpeg, 'new-notation', 0);

      final absPath = await service.getAbsolutePath(relativePath);
      expect(File(absPath).existsSync(), isTrue);
    });

    test('overwrites an existing file with new bytes', () async {
      final original = Uint8List.fromList([0xFF, 0xD8, 0x01]);
      final replacement = Uint8List.fromList([0xFF, 0xD8, 0x02]);

      await service.saveImage(original, 'n1', 0);
      await service.saveImage(replacement, 'n1', 0);

      final absPath =
          await service.getAbsolutePath('notations/n1/page_0_original.jpg');
      expect(File(absPath).readAsBytesSync(), equals(replacement));
    });

    test('different page indices produce distinct paths', () async {
      final path0 = await service.saveImage(_minimalJpeg, 'n1', 0);
      final path1 = await service.saveImage(_minimalJpeg, 'n1', 1);

      expect(path0, isNot(equals(path1)));
    });
  });

  group('FileStorageService.getAbsolutePath', () {
    late Directory tempDir;
    late FileStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fss_test_path_');
      service = _makeService(tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('re-roots relative path under the provided appDocDir', () async {
      const relative = 'notations/n1/page_0_original.jpg';
      final abs = await service.getAbsolutePath(relative);

      expect(abs, equals(p.join(tempDir.path, relative)));
    });

    test('is stable across multiple calls with the same relative path',
        () async {
      const relative = 'notations/n2/page_1_original.jpg';
      final abs1 = await service.getAbsolutePath(relative);
      final abs2 = await service.getAbsolutePath(relative);

      expect(abs1, equals(abs2));
    });
  });

  group('FileStorageService.deletePageFile', () {
    late Directory tempDir;
    late FileStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fss_test_del_page_');
      service = _makeService(tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('removes a file that exists', () async {
      final relativePath = await service.saveImage(_minimalJpeg, 'n1', 0);
      final absPath = await service.getAbsolutePath(relativePath);

      expect(File(absPath).existsSync(), isTrue);

      await service.deletePageFile(relativePath);

      expect(File(absPath).existsSync(), isFalse);
    });

    test('is idempotent when file does not exist', () async {
      // Must not throw.
      await service.deletePageFile('notations/ghost/page_0_original.jpg');
    });

    test('does not remove sibling files in the same directory', () async {
      await service.saveImage(_minimalJpeg, 'n1', 0);
      await service.saveImage(_minimalJpeg, 'n1', 1);

      await service.deletePageFile('notations/n1/page_0_original.jpg');

      final absPath1 =
          await service.getAbsolutePath('notations/n1/page_1_original.jpg');
      expect(File(absPath1).existsSync(), isTrue);
    });
  });

  group('FileStorageService.deleteNotationDirectory', () {
    late Directory tempDir;
    late FileStorageService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fss_test_del_dir_');
      service = _makeService(tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    test('removes the entire notation directory including all pages', () async {
      await service.saveImage(_minimalJpeg, 'n1', 0);
      await service.saveImage(_minimalJpeg, 'n1', 1);

      final dirPath = p.join(tempDir.path, 'notations', 'n1');
      expect(Directory(dirPath).existsSync(), isTrue);

      await service.deleteNotationDirectory('n1');

      expect(Directory(dirPath).existsSync(), isFalse);
    });

    test('is idempotent when directory does not exist', () async {
      // Must not throw.
      await service.deleteNotationDirectory('no-such-notation');
    });

    test('does not affect directories for other notations', () async {
      await service.saveImage(_minimalJpeg, 'n1', 0);
      await service.saveImage(_minimalJpeg, 'n2', 0);

      await service.deleteNotationDirectory('n1');

      final n2DirPath = p.join(tempDir.path, 'notations', 'n2');
      expect(Directory(n2DirPath).existsSync(), isTrue);
    });
  });
}
