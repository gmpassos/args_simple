import 'dart:io';

import 'type_parser.dart';

class TypeParserIO {
  static void register() {
    TypeParser.registerParserResolver(parserResolver);
  }

  static TypeElementParser? parserResolver({Type? t, Object? obj, Type? type}) {
    if (obj != null) {
      if (obj is File) {
        return parseFile;
      } else if (obj is Directory) {
        return parseDirectory;
      }
    }

    type ??= obj?.runtimeType ?? t;

    if (type == File) {
      return parseFile;
    } else if (type == Directory) {
      return parseDirectory;
    }

    return null;
  }

  /// Tries to parse a [File].
  /// - Returns [def] if [value] is invalid.
  static File? parseFile(Object? value, [File? def]) {
    if (value == null) return def;

    if (value is File) {
      return value;
    } else if (value is Directory) {
      return File(value.path);
    } else {
      var s = value.toString().trim();
      if (s.isEmpty) return def;

      return File(s);
    }
  }

  /// Tries to parse a [File].
  /// - Returns [def] if [value] is invalid.
  static Directory? parseDirectory(Object? value, [Directory? def]) {
    if (value == null) return def;

    if (value is Directory) {
      return value;
    } else if (value is File) {
      return Directory(value.path);
    } else {
      var s = value.toString().trim();
      if (s.isEmpty) return def;

      return Directory(s);
    }
  }
}
