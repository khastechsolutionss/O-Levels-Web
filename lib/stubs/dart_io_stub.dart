/// Stub file for dart:io on web platform.
/// Provides minimal implementations of dart:io classes used in the project
/// so the app compiles on web without the actual dart:io library.
library;

// ignore_for_file: camel_case_types

import 'dart:typed_data';

class File {
  final String path;
  File(this.path);

  Future<bool> exists() async => false;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<String> readAsString() async => '';
  Future<File> writeAsBytes(List<int> bytes) async => this;
  Future<File> writeAsString(String contents) async => this;
  Future<void> delete({bool recursive = false}) async {}
  String get absolute => path;
}

class Directory {
  final String path;
  Directory(this.path);

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return const Stream.empty();
  }
}

class FileSystemEntity {
  final String path = '';
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isFuchsia => false;
}

class HttpClient {
  Future<HttpClientRequest> getUrl(Uri url) async =>
      throw UnsupportedError('Not available on web');
  void close({bool force = false}) {}
}

class HttpClientRequest {}

class HttpClientResponse {}
