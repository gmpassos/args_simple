import 'dart:io';
import 'dart:typed_data';
import 'dart:convert' as dart_convert;

import 'package:yaml/yaml.dart';

import 'args_simple_base.dart';
import 'type_parser_io.dart';

extension ArgsSimpleExtension on ArgsSimple {
  File? argumentAsFile(int index, [File? def]) =>
      argument<File>(index, def, TypeParserIO.parseFile);

  String? argumentAsFileContentString(int index, [File? def]) {
    var file = argumentAsFile(index, def);
    return file?.readAsStringSync();
  }

  Uint8List? argumentAsFileContentBytes(int index, [File? def]) {
    var file = argumentAsFile(index, def);
    return file?.readAsBytesSync();
  }

  dynamic argumentAsFileContentJSON(int index, [File? def]) {
    var s = argumentAsFileContentString(index, def);
    return s != null ? dart_convert.json.decode(s) : null;
  }

  dynamic argumentAsFileContentYAML(int index, [File? def]) {
    var s = argumentAsFileContentString(index, def);
    return s != null ? loadYaml(s) : null;
  }

  Directory? argumentAsDirectory(int index, [Directory? def]) =>
      argument<Directory>(index, def, TypeParserIO.parseDirectory);

  File? optionAsFile(String key, [File? def]) =>
      option<File>(key, def, TypeParserIO.parseFile);

  String? optionAsFileContentString(String key, [File? def]) {
    var file = optionAsFile(key, def);
    return file?.readAsStringSync();
  }

  dynamic optionAsFileContentJSON(String key, [File? def]) {
    var s = optionAsFileContentString(key, def);
    return s != null ? dart_convert.json.decode(s) : null;
  }

  dynamic optionAsFileContentYAML(String key, [File? def]) {
    var s = optionAsFileContentString(key, def);
    return s != null ? loadYaml(s) : null;
  }

  Uint8List? optionAsFileContentBytes(String key, [File? def]) {
    var file = optionAsFile(key, def);
    return file?.readAsBytesSync();
  }

  Directory? optionAsDirectory(String key, [Directory? def]) =>
      option<Directory>(key, def, TypeParserIO.parseDirectory);

  File? propertyAsFile(String key, [File? def]) =>
      property<File>(key, def, TypeParserIO.parseFile);

  String? propertyAsFileContentString(String key, [File? def]) {
    var file = propertyAsFile(key, def);
    return file?.readAsStringSync();
  }

  dynamic propertyAsFileContentJSON(String key, [File? def]) {
    var s = propertyAsFileContentString(key, def);
    return s != null ? dart_convert.json.decode(s) : null;
  }

  dynamic propertyAsFileContentYAML(String key, [File? def]) {
    var s = propertyAsFileContentString(key, def);
    return s != null ? loadYaml(s) : null;
  }

  Uint8List? propertyAsFileContentBytes(String key, [File? def]) {
    var file = propertyAsFile(key, def);
    return file?.readAsBytesSync();
  }

  Directory? propertyAsDirectory(String key, [Directory? def]) =>
      property<Directory>(key, def, TypeParserIO.parseDirectory);

  Set<String> loadEnvironment() {
    var envs = Platform.environment;

    var loadedKeys = <String>{};

    for (var e in envs.entries) {
      var v = envs[e.key]!;
      var k = ArgsSimple.normalizeKey(e.key);

      if (!properties.containsKey(k)) {
        putProperty(k, v);
        loadedKeys.add(k);
      }
    }

    return loadedKeys;
  }
}
