import 'dart:io';

import 'package:args_simple/args_simple_io.dart';
import 'package:test/test.dart';

void main() {
  group('ArgsSimple', () {
    test('basic', () {
      var args = ArgsSimple.parse(['a', 'b', '123', '-123']);
      expect(args.arguments, equals(['a', 'b', '123', '-123']));
      expect(args.options, isEmpty);
      expect(args.flags, isEmpty);
      expect(args.properties, isEmpty);

      expect(args.toList(), equals(['a', 'b', '123', '-123']));
    });

    test('with options', () {
      var args = ArgsSimple.parse(['a', '--b', '123', '456', '--x']);
      expect(args.arguments, equals(['a', '456']));
      expect(args.options, equals({'b': '123', 'x': ''}));
      expect(args.flags, isEmpty);
      expect(args.properties, isEmpty);
    });

    test('with flags', () {
      var args = ArgsSimple.parse(['a', '--b', '123', '456', '-x', '-y']);
      expect(args.arguments, equals(['a', '456']));
      expect(args.options, equals({'b': '123'}));
      expect(args.flags, equals({'x', 'y'}));

      expect(args.optionAsInt('b'), equals(123));
      expect(args.optionAsInt('B'), equals(123));
    });

    test('with properties', () {
      var args = ArgsSimple.parse(
          ['a', '--B', '123', '456', '-X', '-y', '-PZzz=WWW', '-DeA']);
      expect(args.arguments, equals(['a', '456']));
      expect(args.options, equals({'b': '123'}));
      expect(args.flags, equals({'x', 'y'}));
      expect(args.properties, equals({'zzz': 'WWW', 'ea': ''}));

      expect(args.toList(),
          equals(['a', '456', '-x', '-y', '--b', '123', '-Pzzz=WWW', '-Pea=']));

      expect(
          args.toJson(),
          equals({
            'arguments': ['a', '456'],
            'flags': {'x', 'y'},
            'options': {'b': '123'},
            'properties': {'zzz': 'WWW', 'ea': ''}
          }));
    });

    test('with File', () {
      var args = ArgsSimple.parse(['a', '--file', 'pubspec.yaml', '456']);
      expect(args.arguments, equals(['a', '456']));

      expect(args.optionAsFile('file')?.path, equals('pubspec.yaml'));
      expect(args.optionAsDirectory('file')?.path, equals('pubspec.yaml'));

      expect(args.toList(), equals(['a', '456', '--file', 'pubspec.yaml']));
    });

    test('loadEnvironment', () {
      var args = ArgsSimple.parse(['a', '--file', 'pubspec.yaml', '456']);
      expect(args.arguments, equals(['a', '456']));

      var size = args.properties.length;

      var loadedKeys = args.loadEnvironment();

      expect(loadedKeys.length, greaterThan(1));

      expect(args.properties.length, greaterThan(size));
    });

    test('isEmpty', () {
      expect(ArgsSimple().isEmpty, isTrue);
      expect(ArgsSimple.parse([]).isEmpty, isTrue);
    });

    test('parse 1', () {
      var args = ArgsSimple.parse('--port 81 -verbose'.split(RegExp(r'\s+')));
      print(args);

      expect(args.isNotEmpty, isTrue);

      var config = args.argumentMatches(0, RegExp(r'.json$'))
          ? args.argumentAsFileContentJSON(0)!
          : {};

      expect(config, equals({}));

      expect(args.argumentAsString(1, 'guest'), 'guest');

      expect(
          args
              .propertyAsDirectory(
                  'sys-config', Directory('/default/sys-config-dir'))!
              .path,
          endsWith('sys-config-dir'));

      expect(args.optionAsInt('port', 8080), equals(81));

      expect(args.flag('verbose'), isTrue);
    });

    test('parse 2', () {
      var args = ArgsSimple.parse('file.json root'.split(RegExp(r'\s+')));
      print(args);

      expect(args.isNotEmpty, isTrue);

      var configFile = args.argumentMatches(0, RegExp(r'.json$'))
          ? args.argumentAsFile(0)!
          : null;

      expect(configFile!.path, endsWith('file.json'));

      expect(args.argumentAsString(1, 'guest'), 'root');

      expect(
          args
              .propertyAsDirectory(
                  'sys-config', Directory('/default/sys-config-dir'))!
              .path,
          endsWith('sys-config-dir'));

      expect(args.optionAsInt('port', 8080), equals(8080));

      expect(args.flag('verbose'), isFalse);
    });

    test('parse 2', () {
      var args =
          ArgsSimple.parse('file.json -Psys-config=/etc'.split(RegExp(r'\s+')));
      print(args);

      expect(args.isNotEmpty, isTrue);

      var configFile = args.argumentMatches(0, RegExp(r'.json$'))
          ? args.argumentAsFile(0)!
          : null;

      expect(configFile!.path, endsWith('file.json'));

      expect(args.argumentAsString(1, 'guest'), 'guest');

      expect(
          args
              .propertyAsDirectory(
                  'sys-config', Directory('/default/sys-config-dir'))!
              .path,
          endsWith('etc'));

      expect(args.optionAsInt('port', 8080), equals(8080));

      expect(args.flag('verbose'), isFalse);
    });
  });
}
